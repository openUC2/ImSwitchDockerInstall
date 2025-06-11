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
wget https://downloads.alliedvision.com/VimbaX/VimbaX_Setup-2025-1-Linux_ARM64.tar.gz

echo "Extracting VimbaX SDK..."
sudo tar -xzf VimbaX_Setup-2025-1-Linux_ARM64.tar.gz -C ${INSTALL_DIR}
sudo mv ${INSTALL_DIR}/VimbaX_2025-1 ${VIMBA_DIR}
rm VimbaX_Setup-2025-1-Linux_ARM64.tar.gz
cd  /opt/VimbaX/cti
echo "Installing GenTL transport layer..."
chmod +x ./Install_GenTL_Path.sh   
sudo ./Install_GenTL_Path.sh   


# Set environment variables permanently
echo "Setting up environment variables..."
GENICAM_GENTL64_PATH="/opt/VimbaX/cti"
EOF

# Add to current session
export GENICAM_GENTL64_PATH="/opt/VimbaX/cti"

echo "VimbaX SDK installation complete!"

echo ""
echo "================================================="
echo " VimbaX SDK Installation Complete"
echo "================================================="
echo ""
echo "IMPORTANT NOTES:"
echo "1. Full VimbaX SDK has been installed with transport layers"
echo "2. GenTL path configured: /opt/VimbaX/cti"
echo "3. VmbPy installed from included wheel file"
echo ""
echo "HOST SYSTEM REQUIREMENTS:"
echo "The Docker container requires USB passthrough from the host."
echo "On the host system, you may need to:"
echo "1. Install appropriate USB drivers for your camera"
echo "2. Set up udev rules for camera access"
echo "3. Ensure the user has access to USB devices"
echo ""
echo "For USB camera access in Docker, use:"
echo "docker run --privileged --device=/dev/bus/usb <image>"
echo ""

