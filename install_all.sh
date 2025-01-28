#!/bin/bash

# install requirements 
sudo apt-get update
sudo apt-get install -y git curl

cd ~/Downloads/ImSwitchDockerInstall
echo "Install Docker"
chmod +x install_docker_raspi.sh
./install_docker_raspi.sh

echo "Pull and Install Docker Image"
chmod +x pull_and_run.sh
./pull_and_run.sh

echo "Clone ImSwitchConfig"
chmod +x git_clone_imswitchconfig.sh
./git_clone_imswitchconfig.sh

echo "Install HIK Driver"
chmod +x install_hikdriver.sh
./install_hikdriver.sh

echo "Install Daheng Driver"
chmod +x install_dahengdriver.sh
./install_dahengdriver.sh

echo "Install Vimba Driver"
chmod +x install_vimba.sh
./install_vimba.sh

echo "Setup RaspAp"
chmod +x install_raspap.sh
./install_raspap.sh

echo "Create Desktop Icons"
chmod +x create_desktopicons.sh
./create_desktopicons.sh

ehco "Set Wallpaper"
chmod +x install_backgroundwallpaper.sh
./install_backgroundwallpaper.sh

echo "Set Autostart for ImSwitch"
chmod +x setup_autostart.sh
./setup_autostart.sh

