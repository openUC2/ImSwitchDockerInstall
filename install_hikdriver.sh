#!/bin/bash -eu
# install_hikdriver.sh
# Install HIK Driver globally

cd /tmp
# list all files in the current directory with their respective sizes
ls -lh

# download the driver
#if [ ! -f MVS_STD_V3.0.1_240902.zip ]; then
# store under /tmp/hikdriver.zip
wget https://www.hikrobotics.com/en2/source/vision/video/2024/9/3/MVS_STD_V3.0.1_240902.zip -O MVS_STD_V3.0.1_240902_1.zip
#fi
#unzip MVS_STD_GML_V2.1.2_231116.zip
echo "Unzip Hik Driver"
unzip MVS_STD_V3.0.1_240902_1.zip 
ls
cd MVS_STD_V3.0.1_240902_1
ls
echo "Install Hik Driver"
sudo dpkg -i MVS-3.0.1_aarch64_20240902.deb
cd /opt/MVS/Samples/aarch64/Python/
cp GrabImage/GrabImage.py MvImport/GrabImage.py
export MVCAM_COMMON_RUNENV=/opt/MVS/lib
export LD_LIBRARY_PATH="/opt/MVS/lib/64:/opt/MVS/lib/32:${LD_LIBRARY_PATH:-}"
# remove old files and directories
rm -rf /tmp/MVS_STD_V3.0.1_240902_1.zip
rm -rf /tmp/MVS_STD_V3.0.1_240902_1
rm -rf /tmp/MVS-3.0.1_aarch64_20240902.deb
echo "Hik Driver Installed"
