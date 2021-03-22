# Install Go

The following set of commands will install go and configure your `$GOPATH` on most linux based systems.

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
