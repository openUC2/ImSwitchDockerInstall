#!/bin/bash -eu
# install_hikdriver.sh
# Install HIK Driver globally

cd /tmp
# list all files in the current directory with their respective sizes
ls -lh

# download the driver
#if [ ! -f MVS_STD_V3.0.1_240902.zip ]; then
# store under /tmp/hikdriver.zip
echo "Install Hik Driver"
wget https://github.com/openUC2/ImSwitchDockerInstall/releases/download/imswitch-master/MVS-3.0.1_aarch64_20241128.deb 
sudo dpkg -i MVS-3.0.1_aarch64_20241128.deb 
cd /opt/MVS/Samples/aarch64/Python/
cp GrabImage/GrabImage.py MvImport/GrabImage.py
export MVCAM_COMMON_RUNENV=/opt/MVS/lib
export LD_LIBRARY_PATH="/opt/MVS/lib/64:/opt/MVS/lib/32:${LD_LIBRARY_PATH:-}"
# remove old files and directories
rm -f MVS-3.0.1_aarch64_20241128.deb
echo "Hik Driver Installed"
