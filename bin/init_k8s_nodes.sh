#!/bin/bash


#Install docker
echo "Installing docker...."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo -S apt-key add -
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
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
apt install zfs -y
echo "... done installing zfs utils"
