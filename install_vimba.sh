#!/bin/bash -eu

# VimbaX Installation Script
# This script installs the full VimbaX SDK for Allied Vision cameras
# Based on the reference implementation from https://github.com/HLiu-uOttawa/Allied-Vision-1800-U-500C

echo "Installing VimbaX SDK for Allied Vision cameras..."

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y python3 python3-pip libusb-1.0-0  wget tar

# Create installation directory
INSTALL_DIR="/opt"
VIMBA_DIR="/opt/VimbaX"



echo "Downloading VimbaX SDK..."
cd /tmp
wget https://github.com/openUC2/ImSwitchDockerInstall/releases/download/imswitch-master/VimbaX_Setup-2025-1-Linux_ARM64.tar.gz

echo "Extracting VimbaX SDK..."
sudo tar -xzf VimbaX_Setup-2025-1-Linux_ARM64.tar.gz -C ${INSTALL_DIR}
sudo mv ${INSTALL_DIR}/VimbaX_2025-1 ${VIMBA_DIR}
rm VimbaX_Setup-2025-1-Linux_ARM64.tar.gz
cd  /opt/VimbaX/cti
echo "Installing GenTL transport layer..."
sudo bash ./Install_GenTL_Path.sh

# Set environment variables permanently
echo "Setting up environment variables..."
sudo bash -c 'echo "export GENICAM_GENTL64_PATH=/opt/VimbaX/cti" > /etc/profile.d/vimbax.sh'

# Add to current session
export GENICAM_GENTL64_PATH="/opt/VimbaX/cti"
pip install https://github.com/alliedvision/VmbPy/releases/download/1.2.1_beta1/vmbpy-1.2.1-py3-none-manylinux_2_27_aarch64.whl
