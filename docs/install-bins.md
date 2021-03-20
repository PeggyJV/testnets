# Install Binaries

## `sommelier` and `oracle-feeder`

If you have a [configured go environment](./install-go.md) the following commands will install `sommelier` and `oracle-feeder` binaries on your system:

```bash
mkdir -p go/src/github.com/peggyjv/
cd go/src/github.com/peggyjv/
git clone https://github.com/peggyjv/sommelier.git
cd sommelier
git checkout main
make install
```

## `orchestrator`, `client` and `register-delegate-keys`

The following commands install the rust orchestrator

```bash
wget https://github.com/althea-net/althea-chain/releases/download/v0.0.4/client
wget https://github.com/althea-net/althea-chain/releases/download/v0.0.4/orchestrator
wget https://github.com/althea-net/althea-chain/releases/download/v0.0.4/register-delegate-keys
chmod +x client orchestrator register-delegate-keys
sudo mv client /usr/bin
sudo mv orchestrator /usr/bin
sudo mv register-delegate-keys /usr/bin
```

## `geth`

The following commands install the `geth` light client node

```bash
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.1-c2d2f4ed.tar.gz
tar -xvf geth-linux-amd64-1.10.1-c2d2f4ed.tar.gz
cd geth-linux-amd64-1.10.1-c2d2f4ed
sudo mv geth /usr/bin/geth
```
