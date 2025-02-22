#!/bin/bash

# install requirements 
sudo apt-get update

# in case they don't exist create Download/Desktop folder (e.g. lite)
mkdir ~/Downloads
mkdir ~/Desktop

cd ~/Downloads/ImSwitchDockerInstall
echo "Install Docker"
chmod +x install_docker_raspi.sh
./install_docker_raspi.sh

echo "Clone ImSwitchConfig"
chmod +x git_clone_imswitchconfig.sh
./git_clone_imswitchconfig.sh

