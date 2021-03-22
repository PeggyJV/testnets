# testnets

The following describes what is requried for a single VM that will act as a validator in a `sommelier` testnet.

## VM Requirements

Compute: 2 CPU
RAM: 8 GB
Disk: 50GB-100GB
Open Ports:

- 26656 (tendermint p2p)
- 26657 (tendermint rpc)
- 9090  (tendermint grpc)
- 1317  (cosmos-sdk api)
- 30303 (geth p2p)

## Dependancies

After you spin up your VM with the above specs, install the following dependancies and configure your unit files:

- [ ] [Install Go](./docs/install-go.md)
- [ ] [Install Binaries](./docs/install-bins.md)
- [ ] [Setup `systemd` unit files](./docs/systemd.md) (Optional but recommended)

## Key generation and `gentx` signature

In this step you will generate your keys that will be used for:

1. Validating on the Cosmos chain
2. Signing for oracle-feeder transactions
3. Signing for ETH transactions
4. Signing for orchestrator transactions

Then you will:

1. Use those keys to sign a `gentx`
2. Gather addresses from each key and some other information to generate a `merlot/addresses/{name}.json` file

```bash
# Initialize config files for both oracle-feeder and sommelier
# NOTE: this also generates ~/.sommelier/config/priv_validator.json that is mission critical
sommelier init moniker --chain-id merlot
oracle-feeder config init 

# backup the mnemonics and private keys that you are generating here
# record the public keys that are generated here as well to create your json file
sommelier keys add validator --keyring-backend test
sommelier keys add orchestrator --keyring-backend test
sommelier eth-keys add
oracle-feeder keys add feeder

# generate the gentx file
sommelier add-genesis-account $(sommelier keys show validator -a --keyring-backend test) 10000000000stake
sommelier gentx validator 1000000000stake --chain-id merlot --keyring-backend test
# this outputs a file path, that is where your gentx.json resides

# Next gather the necessary info for your addesses file
sommelier keys show validator --keyring-backend test -a
sommelier keys show orchestrator --keyring-backend test -a
oracle-feeder keys show feeder
sommelier eth-keys show 1
sommelier tendermint show-node-id
```

## Upload files to testnets repo

Make a PR to this repo with the following files:

#### `./merlot/addresses/{name}.json`

This should contain a json blob with the following schema/data:

```json
{
    "cosmos-addresses": [
        "cosmos18zxhdqsqhx5pl7eyqqgxacwqdxwxx3umj6wvys",
        "cosmos12wms6ghmdsewxpvgzfx39tklnmtmzauf3mqr4p",
        "cosmos1m38004fjd646gncuqlz08p8al5qt7juvze6a48"
    ],
    "eth-address": "0x004cec59a7c332188602079179bd6d4baa4c6a75",
    "node-id": "25f0e83d1f03a8de0956fe858fd8041019d14031",
    "node-ip": "35.247.110.115"
}
```

#### `./merlot/gentx/{name}.json`

This should contain the json from your `gentx` file.

## Configuration Pt 1

Before logging out of your machine, now is a great time to prepare configuration files for both `oracle-feeder` and `sommelier`. Your

### `~/.oracle-feeder/config.yaml`

Your feeder config file should match the one below:

```yaml
uniswap-subgraph: http://35.197.17.185:8000/subgraphs/name/davekaj/uniswap
signing-key: feeder
chain-grpc: http://localhost:9090
chain-rpc: http://localhost:26657
chain-id: merlot
gas-prices: 0.025stake
```

You can test this configuration by running the following:

```bash
# test feeder, this should return a JSON blob
oracle-feeder query uniswap-data
```

### `~/.sommelier/config/app.toml`

To turn on the API, open `~/.sommelier/config/app.toml` in an editor and make the following change to enable the API:

```toml
###############################################################################
###                           API Configuration                             ###
###############################################################################

[api]

# Enable defines if the API server should be enabled.
enable = true
```

## Next steps - Half way point

Now we wait for all testnet participants to submit their files. Once they are submitted we can continue with the network bootstrap process. At this point the `batch` and `il` contracts can be deployed to Goreli. The resultant hashes should be filled in below:

## Deploy ETH Contracts for IL module

- [ ] Deploy `TestTokenBatchMiddleware`
  - [ ] Deploy script/instructions
  - [ ] HASH: `""`
- [ ] Deploy `TestUniswapLiquidity`
  - [ ] Deploy script/instructions
  - [ ] HASH: `""`

## Genesis Mutations

The following changes need to be made to a generated genesis file for sommelier.

- [ ] Add funds to each cosmos address in the `./merlot/addresses/` folder
  - [ ] `sommelier add–genesis-account {address} 1000000000000stake,1000000000000usomm`
- [ ] Add denom metadata for `usomm` and `stake`

    ```bash
    jq '.app_state.bank.denom_metadata += [{"base": "usomm", display: "usomm", "description": "A non-staking test token", "denom_units": [{"denom": "usomm", "exponent": 6}]}, {"base": "stake", display: "stake", "description": "A staking test token", "denom_units": [{"denom": "stake", "exponent": 6}]}]' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [ ] Add contract address for batch contract

    ```bash
    jq '.app_state.il.params.batch_contract_address = "TBD"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [ ] Add contract address for liquidity contract

    ```bash
    jq '.app_state.il.params.liquidity_contract_address = "0xB757488003d0A31f2761Fd8876C6f2bf4a03f740"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [ ] Add chain id for goreli testnet

    ```bash
    jq '.app_state.peggy.params.bridge_chain_id = "5"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [ ] Increase slash window for oracle feeder

    ```bash
    jq '.app_state.oracle.params.slash_window = "1000000"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

## Collect Gentxs and genesis hash

Copy all the `./merlot/gentx/` files into `~/.sommelier/config/gentx/` and run the following:

```bash
sommelier collect-gentxs
jq -S -c -M '' ~/.sommelier/config/genesis.json | shasum -a 256
# HASH: TBD
```

## Configuration Pt 2

Ensure that your `[p2p]persistent_peers` in `~/.sommelier/config/config.toml` contains all the nodes in the `./merlot/addresses/` files. A string will be provided:

```toml
persistent_peers = ""
```

## Start validator

```bash
sudo systemctl start sommelier && journalctl -u sommelier -f
```

At this point the network will begin to come online. The remaining steps are to be completed once the network is online.

## Delegate key to oracle feeder and start oracle feeder

```bash
sommelier tx oracle delegate-feeder $(oracle-feeder keys show feeder) --from validator --chain-id merlot --keyring-backend test
sudo systemctl start oracle-feeder && journalctl -u oracle-feeder -f
# You should see logging for each cosmos block then a set of transactions every 5th block
# Errors will kill this process and set it into a crash backoff loop
```

## Delegate keys for orchestrator

```bash
sommelier tx peggy set-orchestrator-address \
    $(sommelier keys show validator -a --keyring-backend test --bech val) \
    $(oracle-feeder key show feeder) \ 
    $(sommelier eth-keys show 1) \
    # TODO: The below flags are not present on the sommelier binary currently
    --from validator \ 
    --chain-id merlot \ 
    --fees 25000stake \
    --keyring-backend test -y 
```

At this point we need to wait for all genesis participants to submit their eth keys then the peggy contract can be deployed.

## Deploy Peggy

This step only needs to be performed by one participant and should only be run once all the eth keys have been added

```bash
wget https://github.com/althea-net/cosmos-gravity-bridge/releases/download/v0.0.20/contract-deployer
wget https://github.com/althea-net/cosmos-gravity-bridge/releases/download/v0.0.20/Peggy.json
chmod +x contract-deployer
./contract-deployer --cosmos-node="http://localhost:26657" --eth-node="http://localhost:8545" --eth-privkey="{private-key-with-goreli-funds}" --contract=Peggy.json --test-mode=false
```

This results in a hash which is required for all validators to start their orchestrators.

> HASH: `"TBD"`

## Start orchestrators

If you are using the `systemd` setup described here be sure to `sudo systemctl daemon-reload` after editing `/etc/systemd/system/orchestrator.service` to include the peggy contract address and your private keys.

```bash
sudo systemctl start orchestrator && journalctl -u orchestrator -f
# You should see the orchestrator begin to emit logs
```

## WE ARE ALL UP
