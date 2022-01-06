# Zinfandel testnet

The following describes what is requried for a single VM that will act as a validator in the `sommelier` zinfandel testnet. This testnet will involve upgrading from `sommelier` 2.0.0 to 3.0.0, so we will first be installing the earlier binary.

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

## Dependencies

After you spin up your VM with the above specs, install the following dependencies and configure your systemd unit files.

- [ ] [Install Binaries](./docs/install-bins.md)
- [ ] [Set up `gorc` config](./docs/gorc.md)
- [ ] [Set up `systemd` unit files](./docs/systemd.md)

## Key generation and `gentx` signature

In this step you will generate your keys that will be used for:

1. Validating on the Cosmos chain
2. Signing for orchestrator transactions
3. Signing for ETH transactions

Then you will:

1. Use those keys to sign a `gentx`
2. Gather addresses from each key and some other information to generate a `zinfandel/addresses/{name}.json` file

### Initialize the config file for sommelier

> NOTE: this also generates `~/.sommelier/config/priv_validator.json` that is mission critical

```bash
sommelier init moniker --chain-id zinfandel

```

### Create cosmos and ethereum keys

Create backup files of the output of these commands. They contain your private mnemonics and your public addresses for your cosmos and ethereum keys.

```bash
sommelier keys add validator --keyring-backend test
gorc --config ~/gorc/config.toml keys cosmos add orchestrator
gorc --config ~/gorc/config.toml keys eth add signer

```

### Get the delegate key signature

We'll be using the generated signature when we run gentx in the next step.

```bash
echo "0x$(gorc --config ~/gorc/config.toml sign-delegate-keys -a signer $(sommelier keys --keyring-backend test show validator --bech val -a) 0)"

```

### Generate the gentx file

These commands will output a file path pointing to your gentx.json file. Replace <delegate_key_signature> with the value you just generated in the last command.

```bash
sommelier add-genesis-account $(sommelier keys show validator -a --keyring-backend test) 10000000000stake
sommelier gentx validator 1000000000stake $(gorc --config ~/gorc/config.toml keys eth show signer) $(gorc --config ~/gorc/config.toml keys cosmos show orchestrator | cut -d$'\t' -f2) <delegate_key_signature> --chain-id zinfandel --keyring-backend test

```

```bash
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

- [x] Deploy `TestTokenBatchMiddleware`
  - [x] Deploy script/instructions
  - [x] HASH: `"0x439021d5a835C42a7026e71c5a2352602fb41EcE"`
- [x] Deploy `TestUniswapLiquidity`
  - [x] Deploy script/instructions
  - [x] HASH: `"0xB757488003d0A31f2761Fd8876C6f2bf4a03f740"`

## Genesis Mutations

The following changes need to be made to a generated genesis file for sommelier.

- [x] Add funds to each cosmos address in the `./merlot/addresses/` folder
  - [x] `sommelier add–genesis-account {address} 1000000000000stake,1000000000000usomm`
- [x] Add denom metadata for `usomm` and `stake`

    ```bash
    jq '.app_state.bank.denom_metadata += [{"base": "usomm", display: "usomm", "description": "A non-staking test token", "denom_units": [{"denom": "usomm", "exponent": 6}]}, {"base": "stake", display: "stake", "description": "A staking test token", "denom_units": [{"denom": "stake", "exponent": 6}]}]' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Add contract address for batch contract

    ```bash
    jq '.app_state.il.params.batch_contract_address = "0x439021d5a835C42a7026e71c5a2352602fb41EcE"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Add contract address for liquidity contract

    ```bash
    jq '.app_state.il.params.liquidity_contract_address = "0xB757488003d0A31f2761Fd8876C6f2bf4a03f740"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Add chain id for goreli testnet

    ```bash
    jq '.app_state.peggy.params.bridge_chain_id = "5"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Increase slash window for oracle feeder

    ```bash
    jq '.app_state.oracle.params.slash_window = "1000000"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

## Collect Gentxs and genesis hash

Copy all the `./merlot/gentx/` files into `~/.sommelier/config/gentx/` and run the following:

```bash
sommelier collect-gentxs
jq -S -c -M '' ~/.sommelier/config/genesis.json | shasum -a 256
# HASH: fe570afc239e4a935e57f1e170bc9cb647fecd332bdddd5c54015b83b6baaa2d
```

## Configuration Pt 2

Ensure that your `[p2p]persistent_peers` in `~/.sommelier/config/config.toml` contains all the nodes in the `./merlot/addresses/` files. A string will be provided:

```toml
persistent_peers = "25f0e83d1f03a8de0956fe858fd8041019d14031@35.247.110.115:26656,a9f8af97e7bae0fe6ac83d4548ff5328fe6ef087@104.131.106.11:26656,61129d45cea573879d4cd300230e40573965bfcd@10.128.0.5:26656,5580b2bdea2519d44e4e13374174fc340880d51f@198.199.91.35:26656,0f8cdce37d2210572cd9df7099d69ab3bc760d13@ 66.36.234.114:26656"
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
register_delegate_keys
    --validator-phrase=""
    --ethereum-key=""
    --cosmos-phrase=""
    --cosmos-rpc="http://localhost:26657"
    --fees="stake"
```

> TODO: make this work
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
