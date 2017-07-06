FROM ubuntu
RUN apt-get update
RUN apt-get install unzip wget -y
RUN wget https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip
RUN unzip vault_0.7.3_linux_amd64.zip vault
RUN cp vault /usr/bin/vault
CMD vault server -dev -dev-listen-address=0.0.0.0:8200