#!/bin/bash

# install requirements
sudo apt-get update
sudo apt-get install -y git curl

# in case they don't exist create Download/Desktop folder (e.g. lite)
mkdir ~/Downloads
mkdir ~/Desktop

cd ~/Downloads/ImSwitchDockerInstall
echo "Install Docker"
./install_docker_raspi.sh

echo "Pull and Install Docker Image"
./pull_and_run.sh

echo "Clone ImSwitchConfig"
./git_clone_imswitchconfig.sh

echo "Install HIK Driver"
./install_hikdriver.sh

echo "Install Daheng Driver"
./install_dahengdriver.sh

echo "Install Vimba Driver"
./install_vimba.sh

echo "Setup RaspAp"
./install_raspap.sh

echo "Create Desktop Icons"
./create_desktopicons.sh

echo "Set Wallpaper"
./install_backgroundwallpaper.sh

echo "Set install_autostart for ImSwitch"
./install_autostart.sh

# add serial devices to user group
sudo usermod -a -G dialout "$USER"
sudo usermod -a -G tty "$USER"
echo "Please reboot to take effect of adding serial devices to user group"

