## About

This is a python application that acts as a gateway/middle-man between the flow merchant API and Trader Work Station.

Note that this is not the flow merchant API, for that - see https://github.com/laconic-mercenary/flow_merchant.git

It is meant to be run on a machine that has Trader Work Station installed - typically a desktop. 

## Prequisites

- Trader Work Station (TWS)
- python3
- pip3
- venv

## Setup

1. Run Trader Work Station

2. Clone this repository

3. Become root 

4. Place this repoistory in /root

5. Setup TLS certificates
    a. Download the certificate from porkbun.com
    b. Place in .tls directory
    c. Rename to 
        - domain.cert.pem
        - private.key.pem

6. Execute the installation script (you will be prompted to create an API password - make note of this password as flow merchant will need it in an environment variable)
```bash
chmod +x ${REPOSITORY}/infra/ibkr_gateway/linux/root
bash ${REPOSITORY}/infra/ibkr_gateway/linux/root/install.sh
```

7. TLS certificate
    a. Download the certificate from your domain provider (ex: porkbun.com or godaddy.com)
    b. Place in /etc/ibkr_gateway directory
    c. Rename to 
        - domain.cert.pem
        - private.key.pem
    d. Execute
    ```bash
    chown flow_merchant:flow_merchant /etc/ibkr_gateway/*.pem
    chmod 600 /etc/ibkr_gateway/*.pem
    ```

8. Launch Service
```bash
systemctl start ibkr_gateway
```

8. Verify Service and TWS Connectivity
```bash
systemctl status ibkr_gateway
```

## Notes

- Logs

Logs are found in /var/log/ibkr_gateway

- Configs

Configuration files are found in /etc/ibkr_gateway

- Application location

Python scripts are found in /opt/ibkr_gateway

## Post Installation Steps

After verifying the service is running, you will need to add the following environment variables to the flow merchant API

```IBKR_GATEWAY_PASSWORD```

Set this to the password you chose when you ran the installation script.

```IBKR_GATEWAY_ENDPOINT```

Preferrably DNS, but can be IP address. This is the endpoint for the gateway (this python application). 