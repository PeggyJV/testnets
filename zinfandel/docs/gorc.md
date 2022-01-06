# gorc

Before we generate the keystore for gorc, we need to set up a basic config. We're using the `/home/ubuntu` home directory in this example for the `ubuntu` user, but update these values as appropriate for your environment.

```bash
mkdir -p /home/ubuntu/gorc/keystore

```

## config.toml

Place this file at `/home/ubuntu/gorc/config.toml`. We will have to update this config with the Gravity contract address once it has been deployed.

```
keystore = "/home/ubuntu/gorc/keystore/"

[gravity]
contract = ""
fees_denom = "usomm"

[ethereum]
key_derivation_path = "m/44'/60'/0'/0/0"
rpc = "http://localhost:8545"

[cosmos]
key_derivation_path = "m/44'/118'/0'/0/0"
grpc = "http://localhost:9090"
prefix = "somm"
```