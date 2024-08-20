#!/bin/bash
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

echo "Set Autostart for ImSwitch"
chmod +x setup_autostart.sh
./setup_autostart.sh

