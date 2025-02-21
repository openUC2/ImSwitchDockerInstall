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

echo "Install HIK Driver"
chmod +x install_hikdriver.sh
./install_hikdriver.sh

echo "Install Daheng Driver"
chmod +x install_dahengdriver.sh
./install_dahengdriver.sh

echo "Create Desktop Icons"
chmod +x create_desktopicons.sh
./create_desktopicons.sh

echo "Set install_autostart for ImSwitch"
chmod +x install_autostart.sh
./install_autostart.sh
 