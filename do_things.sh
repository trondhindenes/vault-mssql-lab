#create a db
docker exec vaultdev_sqlserver_1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P MyPassword123 -Q "CREATE database testdb"



#create a userpass auth backend:
vault auth-enable userpass
vault write auth/userpass/users/admin password=admin policies=admins
vault policy-write admins /vaultdev/data/policies/admins.hcl

#Switch to the regular "admin" login:
vault auth -method=userpass username=admin password=admin


#activate the database secret backend, and
#create the mssql 'connection'
vault mount database
vault write database/config/mssql plugin_name=mssql-database-plugin connection_url='sqlserver://sa:MyPassword123@sqlserver:1433' allowed_roles="testdb_fullaccess,testdb_readaccess"

#create the role for db read-only access
vault write database/roles/testdb_readaccess db_name=mssql creation_statements="USE [master]; CREATE LOGIN [{{name}}] WITH PASSWORD='{{password}}', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;USE [testdb];CREATE USER [{{name}}] FOR LOGIN [{{name}}];ALTER ROLE [db_datareader] ADD MEMBER [{{name}}];" default_ttl="1m" max_ttl="5m"

#create the role for db full access
vault write database/roles/testdb_fullaccess db_name=mssql creation_statements="USE [master]; CREATE LOGIN [{{name}}] WITH PASSWORD='{{password}}', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;USE [testdb];CREATE USER [{{name}}] FOR LOGIN [{{name}}];ALTER ROLE [db_owner] ADD MEMBER [{{name}}];" default_ttl="1m" max_ttl="5m"

#create a policy for db read-only access. Note that we're not creating one for full access
vault policy-write testdb_readaccess /vaultdev/data/policies/testdb_readaccess.hcl

#test the thing
vault read database/creds/testdb_readaccess
vault read database/creds/testdb_fullaccess

#Enable the approle auth backend:
vault auth-enable approle
vault write auth/approle/role/testdb_readaccess role_id=test secret_id_ttl=10m token_num_uses=10 token_ttl=20m token_max_ttl=30m secret_id_num_uses=40 policies=testdb_readaccess
vault read auth/approle/role/testdb_readaccess/role-id

#Get a secretId
vault write -f auth/approle/role/testdb_readaccess/secret-id

#Login as the app role
vault write auth/approle/login role_id=test secret_id=a5f36495-aa4e-72f4-3364-d22979070f77
vault auth 