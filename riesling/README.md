# Riesling testnet

The following describes what is required for a single VM that will act as a validator in the `sommelier` riesling testnet. This testnet will involve upgrading from `sommelier` 7.0.1 to 8.0.0, so we will first be installing the earlier binary. We will later be replacing our usage of `steward` with `steward` as this is the same transition the validators will be going through.

Use a recent Ubuntu image when creating your VM.

## VM Requirements

Compute: 2 CPU
RAM: 8 GB
Disk: 50GB-100GB
Open Ports:

- 26656 (tendermint p2p)
- 26657 (tendermint rpc)
- 9090  (tendermint grpc)
- 1317  (cosmos-sdk api)

## Dependencies

After you spin up your VM with the above specs, install the following dependencies and configure your systemd unit files.

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install wget build-essential git nano jq make snapd -y

```

### Install binaries

#### `sommelier`

```bash
cd ~
mkdir sommelier_7.0.1_linux_amd64
cd sommelier_7.0.1_linux_amd64
wget https://github.com/PeggyJV/sommelier/releases/download/v7.0.1/sommelier_7.0.1_linux_amd64.tar.gz
tar -xvf sommelier_7.0.1_linux_amd64.tar.gz
sudo cp sommelier /usr/bin/sommelier
cd ~

```

Run the steward build script

```bash
mkdir steward_4.2.7_linux_amd64
cd steward_4.2.7_linux_amd64
wget https://github.com/PeggyJV/steward/releases/download/v4.2.7/steward_4.2.7_linux_amd64.tar.gz
tar -xvf steward_4.2.7_linux_amd64.tar.gz
sudo cp steward /usr/bin/steward

```

### Set up configs

#### `steward`

Before we generate the keystore for steward, we need to set up a basic config. We're using the `/home/ubuntu` home directory in this example for the `ubuntu` user, but update these values as appropriate for your environment.

```bash
mkdir -p /home/ubuntu/steward/keystore

```

Place this file at `/home/ubuntu/steward/config.toml`. We will have to update this config with the Gravity contract address once it has been deployed. You will need to replace "<eth_node_url>" with a valid Alchemy or Infura endpoint for Goerli.

```
keystore = "/home/ubuntu/steward/keystore/"

[gravity]
contract = ""
fees_denom = "usomm"

[keys]
delegate_key = "orchestrator"

[ethereum]
key_derivation_path = "m/44'/60'/0'/0/0"
rpc = "<eth_node_url>"

[cosmos]
key_derivation_path = "m/44'/118'/0'/0/0"
grpc = "http://localhost:9090"
prefix = "somm"
gas_limit_per_msg = 60_000_000

[cosmos.gas_price]
amount = 0.0
denom = "usomm"

[cork]
cache_refresh_period = 10
proposal_poll_period = 10
max_scheduling_retries = 5

[pubsub]
cache_refresh_period = 10
```

### Set up `systemd` unit files

The following are example systemd unit files to help you manage the variety of services we are running to support the network. Systemd unit files live in `/etc/systemd/system/` and any changes in that folder require a restart of the the systemd process to take effect: `sudo systemctl daemon-reload`

> NOTE: These files are all written for the `ubuntu` user. The user on your system may be different as well as having different `ExecStart` locations. Make sure the files are customized for your environment!!!

#### `/etc/systemd/system/sommelier.service`

```
[Unit]
Description=Sommelier Node
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/sommelier start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

#### `/etc/systemd/system/orchestrator.service`

> NOTE: The cosmos-key and ethereum-key arguments are referencing keys we will be creating at a later step.

```
[Unit]
Description=Sommelier Orchestrator
After=online.target

[Service]
Type=simple
User=ubuntu
Environment="RUST_LOG=INFO"
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/steward --config /home/ubuntu/steward/config.toml orchestrator start --cosmos-key orchestrator --ethereum-key signer --orchestrator-only
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

## Key generation and `gentx` signature

In this step you will generate your keys that will be used for:

1. Validating on the Cosmos chain
2. Signing for orchestrator transactions
3. Signing for ETH transactions

Then you will:

1. Use those keys to sign a `gentx`
2. Gather addresses from each key and some other information to generate a `riesling/addresses/{name}.json` file

### Initialize the config file for sommelier

> NOTE: this also generates `~/.sommelier/config/priv_validator.json` that is mission critical

```bash
sommelier init moniker --chain-id riesling

```

### Create Cosmos and Ethereum keys

Create backup files of the output of these commands. They contain your private mnemonics and your public addresses for your Cosmos and Ethereum keys.

```bash
sommelier keys add validator --keyring-backend test
steward --config ~/steward/config.toml keys cosmos add orchestrator
steward --config ~/steward/config.toml keys eth add signer

```

### Get the delegate key signature

We'll be using the generated signature when we run gentx in the next step.

```bash
echo $(steward --config ~/steward/config.toml sign-delegate-keys signer $(sommelier keys --keyring-backend test show validator --bech val -a) 0)

```

### Generate the gentx file

These commands will output a file path pointing to your gentx.json file. Replace <delegate_key_signature> with the value you just generated in the last command. If that value does not have a 0x prepended in front of it, you will need to add it. You will also need to replace <node_id> with the output of `sommelier tendermint show-node-id` and <ip_address> with the public-facing IP address of your server.

```bash
sommelier add-genesis-account $(sommelier keys show validator -a --keyring-backend test) 10000000000usomm
sommelier gentx validator 1000000000usomm $(steward --config ~/steward/config.toml keys eth show signer | cut -d$'\t' -f2) $(steward --config ~/steward/config.toml keys cosmos show orchestrator | cut -d$'\t' -f2) <delegate_key_signature> --chain-id riesling --keyring-backend test --note "<node_id>@<ip_address>:26656"

```

## Upload files to testnets repo

Make a PR to this repo with the following files:

### `./riesling/addresses/{name}.json`

Run the following set of commands to print out your validator address, orchestrator address, ethereum address, node ID, and network information to retrieve your IP address.

```bash
sommelier keys show validator --keyring-backend test -a
steward --config ~/steward/config.toml keys cosmos show orchestrator | cut -d$'\t' -f2
steward --config ~/steward/config.toml keys eth show signe | cut -d$'\t' -f2
sommelier tendermint show-node-id
hostname -I | cut -d " " -f1

```

If the last command doesn't give you a publicly routable IP, try running it without the pipe to `cut` and pick the correct IP address. If you are using a hosting provider with a different external IP address than the one reported by your machine, you will need to use that for your addresses file.

Fill out `./riesling/addresses/{name}.json` with the following schema using the data we just printed above:

```json
{
    "somm-addresses": [
        "somm18zxhdqsqhx5pl7eyqqgxacwqdxwxx3umj6wvys",
        "somm12wms6ghmdsewxpvgzfx39tklnmtmzauf3mqr4p"
    ],
    "eth-address": "0x004cec59a7c332188602079179bd6d4baa4c6a75",
    "node-id": "25f0e83d1f03a8de0956fe858fd8041019d14031",
    "node-ip": "35.247.110.115"
}
```

### `./riesling/gentx/{name}.json`

This should contain the json from your `gentx` file. The output will be compact, you can prettify it by running:

```bash
cat <gentx_file_path> | jq

```

## Update the configuration

Before logging out of your machine, now is a great time to prepare the configuration file for `sommelier`.

### Set minimum gas prices

The first config entry should be for minimum-gas-prices, which should be set to "0usomm".

### Enable the API

To turn on the API, open `~/.sommelier/config/app.toml` in an editor and make the following change to enable the API:

```toml
###############################################################################
###                           API Configuration                             ###
###############################################################################

[api]

# Enable defines if the API server should be enabled.
enable = true
```

## Next steps - stop here

Now we wait for all testnet participants to submit their files. Once they are submitted we can continue with the network bootstrap process. Do not proceed further if the network has not been started yet.

## Genesis Mutations

The following changes need to be made to a generated genesis file for sommelier.

- [x] Add funds to each cosmos address in the `./riesling/addresses/` folder

  ```bash
  sommelier add-genesis-account somm179j7hx3tquu960j8kaf62tdnkywddyj2r2fmpf 1000000000000usomm
  sommelier add-genesis-account somm199sjfhaw3hempwzljw0lgwsm9kk6r8e5vhl2uw 1000000000000usomm
  sommelier add-genesis-account somm1dts09p42gclsxl7xnumek3nj930uhdxnat90wu 1000000000000usomm
  sommelier add-genesis-account somm13hga6cqmv94xdjm5vka77hec94ygumsk4fd6jf 1000000000000usomm
  sommelier add-genesis-account somm1ldsrh5f0pls7awfmgerppgdlkjl4rvwgac2lu3 1000000000000usomm
  sommelier add-genesis-account somm10els3w56cn3gq8uwje45ws7u9c5mqfgjngrm3f 1000000000000usomm
  sommelier add-genesis-account somm1lcll2tvggqft0f3tzmh4aj40ydp9gty72y60eg 1000000000000usomm
  sommelier add-genesis-account somm1zyteclqhjm9vsf66svqxntq8g85vncr9km2920 1000000000000usomm
  sommelier add-genesis-account somm1qwmp82dryjl8as03w7n2c262as8afdm4eelkjh 1000000000000usomm
  sommelier add-genesis-account somm1lqlvyhe04fshuckdsm2ye0xj0uk48tl4qgs43c 1000000000000usomm
  ```

- [x] Add denom metadata for `usomm`

    ```bash
    jq '.app_state.bank.denom_metadata += [{"base": "usomm", "display": "usomm", "description": "A staking test token", "name": "Somm", "symbol": "SOMM", "denom_units": [{"denom": "usomm", "exponent": 0}]}]' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Add chain id for Goerli testnet

    ```bash
    jq '.app_state.gravity.params.bridge_chain_id = "5"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Shorten governance voting window to 10 minutes

    ```bash
    jq '.app_state.gov.voting_params.voting_period = "600s"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Shorten unbonding time to 5 minutes

    ```bash
    jq '.app_state.staking.params.unbonding_time = "300s"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Replace references to "stake" with "usomm"

    ```bash
    jq '.app_state.crisis.constant_fee.denom = "usomm"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    jq '.app_state.gov.deposit_params.min_deposit[0].denom = "usomm"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    jq '.app_state.mint.params.mint_denom = "usomm"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    jq '.app_state.staking.params.bond_denom = "usomm"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

## Collect gentxs and genesis hash

Copy all the `./riesling/gentx/` files into `~/.sommelier/config/gentx/` and run the following:

```bash
sommelier collect-gentxs
jq -S -c -M '' ~/.sommelier/config/genesis.json | shasum -a 256

```

Expected hash: `b709cfb67f64f1d08fe2d2d71d2c10d0d2fe6172256d065e015a767073a39ae2`

## Configure persistent peers

Ensure that your `[p2p]persistent_peers` in `~/.sommelier/config/config.toml` contains all the nodes in the `./riesling/addresses/` files. A string will be provided:

```toml
persistent_peers = "a49554156f5cc3a7b57482c5a38dc374293004fa@34.125.217.119:26656,aa464baad9f0228e63025bedd4e5c00f16419522@164.92.91.176:26656,048fcedf274f1382780eb658ecb57ba475d4e2ca@3.84.45.235:26656,b599397a5644357f3179d358d98bf943fbd5bf44@164.92.131.147:26656,d6207eb3898e9e1f59699cc0acec64bf15b80d37@34.133.226.219:26656"

```

## Start validator

```bash
sudo systemctl start sommelier && journalctl -u sommelier -f

```

At this point the network will begin to come online. The remaining steps are to be completed once the network is online.

## Deploy Gravity contract

This step only needs to be performed by one participant and should only be run once all the eth keys have been added. You will need to replace "<eth_node_url>" with the Alchemy or Infura endpoint used for this test (should be located in your ~/steward/config.toml file) and "<eth_private_key>" with the ethereum private key you are using to deploy the contract. For this test, you can use the signer key that was created for the orchestrator. The private key can be retrieved using the following command, and when you submit it, drop the 0x prefix:

```bash
steward --config ~/steward/config.toml keys eth show signer --show-private-key

```

```bash
cd ~
mkdir contract_4.0.0
cd contract_4.0.0
wget https://github.com/PeggyJV/gravity-bridge/releases/download/v4.0.0/contract-deployer
wget https://github.com/PeggyJV/gravity-bridge/releases/download/v4.0.0/Gravity.json
chmod +x contract-deployer
./contract-deployer --eth-node "<eth_node_url>" --cosmos-node "localhost:26657" --eth-privkey <eth_private_key> --contract Gravity.json --test-mode false
cd ~

```

Take the resultant address of the deployed contract and edit your ~/steward/config.toml file to set the contract address.

## Start orchestrators

If you are using the `systemd` setup described here be sure to `sudo systemctl daemon-reload` after editing `/etc/systemd/system/orchestrator.service` to include the Gravity contract address.

```bash
sudo systemctl start orchestrator && journalctl -u orchestrator -f

```

You should see the orchestrator begin to emit logs.

## Deploy the test ERC20s

## Bridge test ERC20 tokens to Cosmos

## Bridge a Cosmos-originated token to Ethereum

## Submit the governance proposal

You will need to replace "<upgrade_height>" with the appropriate block height at which the upgrade will be required. First, we will consider how long the governance vote period will last and add a decent chunk of minutes as buffer time. Since we have manually set our vote periods to 10 minutes, we'll wait 15 minutes from voting start to trigger the upgrade. Watch the sommelier node logs to estimate how long each block takes to get committed and calculate how many blocks to wait. In this particular case we will likely observe roughly 6 second blocks, meaning 10 blocks per minute and thus adding 150 blocks to the current block height to determine the upgrade height.

```bash
sommelier tx gov submit-proposal software-upgrade v4 --upgrade-height <upgrade_height> --deposit 100000usomm --from <proposal_submitter> --keyring-backend test --title v4 --description "Testing v4 upgrade" --chain-id riesling

```

## Vote for the proposal

Each validator must submit their vote so the upgrade proposal can proceed.

```bash
sommelier tx gov vote 1 Yes --from foo --chain-id riesling -y --keyring-backend test

```

## Upgrade the binaries

Wait until the upgrade height after passing the proposal. The sommelier node should panic and require the CabernetFranc upgrade, which will be present in the updated binary. At this point, you should shut down the orchestrator.

```bash
sudo systemctl stop orchestrator

```

### Set up Go

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install wget build-essential git nano jq make snapd -y
sudo snap install go --classic
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.profile
echo "export GOPATH=$HOME/go" >> ~/.profile
echo "export GOBIN=$HOME/go/bin" >> ~/.profile
source ~/.profile

```

### Set up Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

```

### Clone the repos

```bash
cd ~
git clone https://github.com/PeggyJV/sommelier.git
git clone https://github.com/PeggyJV/steward.git

```

Replace the binary for `sommelier`. It's fine to do this with the sommelier node running, the current binary is already in memory.

```bash
echo todo

```

Restart the sommelier node and monitor logs to ensure the upgrade has applied cleanly and that blocks are being produced once each validator has upgraded.

```bash
sudo systemctl restart sommelier && journalctl -u sommelier -f

```

Start the orchestrator:

```bash
sudo systemctl start orchestrator && journalctl -u orchestrator -f

```

## Deploy the test cellar

## Start Steward

## Testing items

### Bridge test ERC20 token #2 to Cosmos

### Bridge a Cosmos-originated token to Ethereum

### Cellar addition governance proposal

### Submit a cork via steward

### Cellar removal governance proposal

### Fund an Ethereum address with a community pool proposal

#### Fund the community pool

```bash
sommelier tx distribution fund-community-pool 10000000usomm

```

#### Create governance proposal for community pool spend

### Send Ethereum tokens to the cellar fees module account

### Cellar shutdown via scheduled cork
