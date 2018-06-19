#!/bin/bash

# adding hostname to /etc/hosts
echo "Adding $(hostname) to /etc/hosts file"
echo "127.0.0.1 $(hostname)" >> /etc/hosts

# Install docker
echo "Installing docker...."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo -S apt-key add -
sudo -S apt remove docker.io
sudo -S apt update
sudo -S add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo -S apt update
sudo -S apt upgrade -y
sudo -S apt install docker-ce -y
echo "...docker installation complete."
echo
echo "installing conntrack..."
apt install conntrack
echo "... done installing conntrack"
echo
echo "installing zfs utils..."
apt install zfsutils-linux -y
echo "... done installing zfs utils"
echo
echo "installing dnsmasq utils..."
apt install dnsmasq -y
echo "... done installing dnsmasq utils"
