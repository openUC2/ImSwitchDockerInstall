#!/bin/bash

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y wget tar

# Download and extract the arm64 build of Vimba
wget https://downloads.alliedvision.com/Vimba_v6.0_Linux_arm64.tgz -O /tmp/Vimba_arm64.tgz
sudo tar -xzf /tmp/Vimba_arm64.tgz -C /opt
rm /tmp/Vimba_arm64.tgz

# Install the USB transport layer
cd /opt/Vimba_6_0/VimbaUSBTL
sudo ./Install.sh

# Install Python bindings (pymba / VimbaPython)
cd /opt/Vimba_6_0/VimbaPython/Source
sudo python3 -m pip install .

# Export environment variable for GenTL detection (add to ~/.bashrc as needed)
export GENICAM_GENTL64_PATH="$GENICAM_GENTL64_PATH:/opt/Vimba_6_0/VimbaUSBTL/CTI/arm_64bit"

echo "Vimba installation complete."
