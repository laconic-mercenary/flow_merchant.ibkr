## Prequisites

- Trader Work Station (TWS)
- Python3
- pip3
- venv

## Setup

1. Run Trader Work Station

2. Create a virtual environment
```bash
python3 -m venv venv
source venv/bin/activate
```

3. Install dependencies
```bash
pip3 install -r requirements.txt
```

4. TLS certificate
    a. Download the certificate from porkbun.com
    b. Place in ./.tls directory
    c. Rename to 
        - domain.cert.pem
        - private.key.pem

## Execution
5. Run main
```bash
python3 main.py gateway-password=(the API password)
```

Note: gateway-password is the password for the API to receive requests from Azure (which receives requests from Trading View) - this is NOT the password for Trader Work Station.