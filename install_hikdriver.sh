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
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    HIK_ARCH="aarch64"
    HIK_SAMPLE_PATH="aarch64"
elif [ "$ARCH" = "x86_64" ]; then
    HIK_ARCH="x86_64"
    HIK_SAMPLE_PATH="64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

HIK_DEB_FILE="MVS-3.0.1_${HIK_ARCH}_20241128.deb"
wget https://github.com/openUC2/ImSwitchDockerInstall/releases/download/imswitch-master/${HIK_DEB_FILE}
sudo dpkg -i ${HIK_DEB_FILE}
cd /opt/MVS/Samples/${HIK_SAMPLE_PATH}/Python/
cp GrabImage/GrabImage.py MvImport/GrabImage.py
export MVCAM_COMMON_RUNENV=/opt/MVS/lib
export LD_LIBRARY_PATH="/opt/MVS/lib/64:/opt/MVS/lib/32:${LD_LIBRARY_PATH:-}"
# remove old files and directories
rm -f ${HIK_DEB_FILE}
echo "Hik Driver Installed"
