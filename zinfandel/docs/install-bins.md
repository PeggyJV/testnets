# Install Binaries

## `sommelier` and `oracle-feeder`

If you have a [configured go environment](./install-go.md) the following commands will install the `sommelier` binary on your system:

```bash
cd ~
mkdir -p go/src/github.com/peggyjv/
cd go/src/github.com/peggyjv/
git clone https://github.com/peggyjv/sommelier.git
cd sommelier
git checkout main
make install
cd ~
sudo cp go/bin/sommelier /usr/bin/sommelier
```

Alternatively, you can install the sommelier binary from an existing release:

```bash
cd ~
mkdir sommelier_3.0.0_linux_amd64
cd sommelier_3.0.0_linux_amd64
wget https://github.com/PeggyJV/sommelier/releases/download/v3.0.0/sommelier_3.0.0_linux_amd64.tar.gz
tar -xvf sommelier_3.0.0_linux_amd64.tar.gz
sudo cp sommelier /usr/bin/sommelier
cd ~
```

## `orchestrator`, `client` and `register-delegate-keys`

The following commands install the rust orchestrator

```bash
cd ~
wget https://github.com/PeggyJV/gravity-bridge/releases/download/v0.3.1/gorc
wget https://github.com/PeggyJV/gravity-bridge/releases/download/v0.3.1/register-delegate-keys
chmod +x gorc register-delegate-keys
sudo mv gorc /usr/bin
sudo mv register-delegate-keys /usr/bin
```

## `geth`

The following commands install the `geth` light client node

```bash
cd ~
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.1-c2d2f4ed.tar.gz
tar -xvf geth-linux-amd64-1.10.1-c2d2f4ed.tar.gz
cd geth-linux-amd64-1.10.1-c2d2f4ed
sudo cp geth /usr/bin/geth
cd ~
```
