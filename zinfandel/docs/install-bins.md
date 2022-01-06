# Install Binaries

## `sommelier`

The following commands will install the `sommelier` binary on your system:

```bash
cd ~
mkdir sommelier_3.0.0_linux_amd64
cd sommelier_3.0.0_linux_amd64
wget https://github.com/PeggyJV/sommelier/releases/download/v3.0.0/sommelier_3.0.0_linux_amd64.tar.gz
tar -xvf sommelier_3.0.0_linux_amd64.tar.gz
sudo cp sommelier /usr/bin/sommelier
cd ~
```

## `gorc` and `register-delegate-keys`

The following commands install the rust orchestrator binaries on your system:

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
