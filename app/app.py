from os import getenv
import pymssql
import hvac
import time
import sys
import datetime

sqlserver_address = None
sql_user = None
sql_password = None
vault_is_authenticated = False
client = None
sql_lease_expires = None

def do_sql_query():
    conn = pymssql.connect(sqlserver_address, sql_user, sql_password, "testdb")
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM SYSOBJECTS')
    print("number of responses from sql server: " + str(len(list(cursor))))
    conn.close()

def vault_auth(vault_url, vault_role_id, vault_secret_id, client=None):
    print("authenticating to Vault")
    if client is None:
        client = hvac.Client(url=vault_url)
    client.token = client.auth_approle(vault_role_id, vault_secret_id)['auth']['client_token']
    return client

if __name__ == '__main__':
    print("Starting app")
    while True:
        sqlserver_address = getenv("SQL_SERVER_ADDR")
        vault_url = getenv("VAULT_URL")
        vault_role_id = getenv("ROLE_ID")
        vault_secret_id = getenv("SECRET_ID")

        now = datetime.datetime.now()
        test_lease = now + datetime.timedelta(0, 30)
        
        if sql_lease_expires and test_lease > sql_lease_expires:
            do_reauth_sql = True
        else:
            do_reauth_sql = False

        if vault_is_authenticated is False:
            client = vault_auth(vault_url, vault_role_id, vault_secret_id)
            vault_is_authenticated = True

        if sql_user is None or sql_password is None or do_reauth_sql is True:
            print("getting/updating sql server credentials")
            now = datetime.datetime.now()
            sql_creds = client.read('database/creds/testdb_readaccess')
            sql_password = sql_creds['data']['password']
            sql_user = sql_creds['data']['username']
            sql_lease_expires = now + datetime.timedelta(0, sql_creds['lease_duration'])
        else:
            #print("sql server creds still valid")
            pass

        do_sql_query()
        time.sleep(2)