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

## Dependencies

After you spin up your VM with the above specs, install the following dependencies and configure your systemd unit files.

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install wget build-essential git nano jq make snapd -y

```

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
echo $(gorc --config ~/gorc/config.toml sign-delegate-keys -a signer $(sommelier keys --keyring-backend test show validator --bech val -a) 0)

```

### Generate the gentx file

These commands will output a file path pointing to your gentx.json file. Replace <delegate_key_signature> with the value you just generated in the last command. If that value does not have a 0x prepended in front of it, you will need to add it.

```bash
sommelier add-genesis-account $(sommelier keys show validator -a --keyring-backend test) 10000000000stake
sommelier gentx validator 1000000000stake $(gorc --config ~/gorc/config.toml keys eth show signer) $(gorc --config ~/gorc/config.toml keys cosmos show orchestrator | cut -d$'\t' -f2) <delegate_key_signature> --chain-id zinfandel --keyring-backend test

```

## Upload files to testnets repo

Make a PR to this repo with the following files:

### `./zinfandel/addresses/{name}.json`

Run the following set of commands to print out your validator address, orchestrator address, ethereum address, node ID, and network information to retrieve your IP address.

```bash
sommelier keys show validator --keyring-backend test -a
gorc --config ~/gorc/config.toml keys cosmos show orchestrator | cut -d$'\t' -f2
gorc --config ~/gorc/config.toml keys eth show signer
sommelier tendermint show-node-id
hostname -I | cut -d " " -f1

```

If the last command doesn't give you a publicly routable IP, try running it without the pipe to `cut` and pick the correct IP address.

Fill out `./zinfandel/addresses/{name}.json` with the following schema/data using the data we just printed above:

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

### `./zinfandel/gentx/{name}.json`

This should contain the json from your `gentx` file. The output will be compact, you can prettify it by running:

```bash
cat <gentx_file_path> | jq

```

## Configuration Pt 1

Before logging out of your machine, now is a great time to prepare the configuration file for `sommelier`.

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

Now we wait for all testnet participants to submit their files. Once they are submitted we can continue with the network bootstrap process.

## Genesis Mutations

The following changes need to be made to a generated genesis file for sommelier.

- [x] Add funds to each cosmos address in the `./zinfandel/addresses/` folder
  - [x] `sommelier add–genesis-account {address} 1000000000000stake,1000000000000usomm`
- [x] Add denom metadata for `usomm` and `stake`

    ```bash
    jq '.app_state.bank.denom_metadata += [{"base": "usomm", display: "usomm", "description": "A non-staking test token", "denom_units": [{"denom": "usomm", "exponent": 6}]}, {"base": "stake", display: "stake", "description": "A staking test token", "denom_units": [{"denom": "stake", "exponent": 6}]}]' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

- [x] Add chain id for goreli testnet

    ```bash
    jq '.app_state.peggy.params.bridge_chain_id = "5"' ~/.sommelier/config/genesis.json > ~/.sommelier/config/edited-genesis.json
    mv ~/.sommelier/config/edited-genesis.json ~/.sommelier/config/genesis.json
    ```

## Collect Gentxs and genesis hash

Copy all the `./zinfandel/gentx/` files into `~/.sommelier/config/gentx/` and run the following:

```bash
sommelier collect-gentxs
jq -S -c -M '' ~/.sommelier/config/genesis.json | shasum -a 256
# HASH: 001a0d48a82ff374b3ff22e6552c342b3b93d5d443150b5a78b07284d3de8ab3
```

## Configuration Pt 2

Ensure that your `[p2p]persistent_peers` in `~/.sommelier/config/config.toml` contains all the nodes in the `./zinfandel/addresses/` files. A string will be provided:

```toml
persistent_peers = "1d86bf16f5709ab8afcd2e0501619ed3b0805cac@35.197.62.120:26656,2141ae992abc58fb4d88ce2b743e9283abfb4209@147.182.229.248:26656,f8130b0f831faac68b948adf56ce09e34825d629@34.71.31.2:26656,b352955a2343e7e409030666a9cdd036b7fe3721@35.226.109.154:26656,50ab8b874ec4de485115aa922793a0e83729348d@35.226.103.234:26656"
```

## Start validator

```bash
sudo systemctl start sommelier && journalctl -u sommelier -f
```

At this point the network will begin to come online. The remaining steps are to be completed once the network is online.

## Deploy Gravity contract

This step only needs to be performed by one participant and should only be run once all the eth keys have been added.

```bash
wget https://github.com/PeggyJV/gravity-bridge/releases/download/v0.2.23/contract-deployer
wget https://github.com/PeggyJV/gravity-bridge/releases/download/v0.2.23/Gravity.json
chmod +x contract-deployer
./contract-deployer --eth-node "<eth_node_url>" --cosmos-node "localhost:26657" --eth-privkey <eth_private_key> --contract Gravity.json --test-mode false
```

Take the resultant address of the deployed contract and edit your ~/gorc/config.toml file to set the contract address.

## Start orchestrators

If you are using the `systemd` setup described here be sure to `sudo systemctl daemon-reload` after editing `/etc/systemd/system/orchestrator.service` to include the Gravity contract address.

```bash
sudo systemctl start orchestrator && journalctl -u orchestrator -f

```

You should see the orchestrator begin to emit logs.

## Generate some ethereum state

Part of the upgrade process will be wiping the Ethereum state as we migrate to a new contract. In order to verify this is working correctly, we must generate some ethereum events so there is state to wipe. The simplest way to do this is by making a large delegation to another validator, waiting to verify in the orchestrator logs that a valset update has completed, and this repeating this process a few times. This will push forward the ethereum event nonce and include some ethereum voting records on chain.

## Submit the governance proposal

You will need to replace "<upgrade_height>" with the appropriate block height at which the upgrade will be required. First, we will consider how long the governance vote period will last and add a decent chunk of minutes as buffer time. Since we have manually set our vote periods to 10 minutes, we'll wait 15 minutes from voting start to trigger the upgrade. Watch the sommelier node logs to estimate how long each block takes to get committed and calculate how many blocks to wait. In this particular case we will likely observe roughly 6 second blocks, meaning 10 blocks per minute and thus adding 150 blocks to the current block height to determine the upgrade height.

```bash
sommelier tx gov submit-proposal software-upgrade CabFranc --upgrade-height <upgrade_height> --deposit 100000stake --from foo --keyring-backend test --title CabFranc --description "foo" --chain-id zinfandel

```

## Vote for the proposal

Each validator must submit their vote so the upgrade proposal can proceed.

```bash
sommelier tx gov vote 1 Yes --from foo --chain-id zinfandel -y --keyring-backend test

```

## Upgrade the binaries

Wait until the upgrade height after passing the proposal. The sommelier node should panic and require the CabFranc upgrade, which will be present in the updated binary. At this point, you should shut down the orchestrator.

```bash
sudo systemctl stop orchestrator

```

## TODO(bolten): binary replacement, chain restart, new contract deployment, orchestrator restart