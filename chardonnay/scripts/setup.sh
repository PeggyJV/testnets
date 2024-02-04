set -e

apt update -y
apt upgrade -y
apt install sudo
sudo DEBIAN_FRONTEND=noninteractive apt install wget build-essential git nano jq make snapd curl -y

