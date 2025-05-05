#!/bin/bash
# chmod +x install_galaxy_sdk.sh
# ./install_galaxy_sdk.sh
set -e

# Set timezone
export TZ=America/Los_Angeles
export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
echo $TZ > /etc/timezone

# Update and install required packages
sudo apt-get update && sudo apt-get install -y \
    wget \
    unzip \
    python3 \
    python3-pip \
    usbutils \
    sudo \
    nano \
    git \
    expect

# Create udev rules directory
sudo mkdir -p /etc/udev/rules.d

# Temporary working directory
cd /tmp

# Download SDKs
wget https://dahengimaging.com/downloads/Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz
wget https://dahengimaging.com/downloads/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip

# Extract
unzip Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip
tar -zxvf Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz

# Build and install Python API
cd /tmp/Galaxy_Linux_Python_2.0.2106.9041/api
python3 setup.py build
sudo python3 setup.py install

# Install Galaxy camera driver (simulate Enter keys)
cd /tmp/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202
chmod +x Galaxy_camera.run
expect <<EOF
spawn sudo ./Galaxy_camera.run
expect {
    "Do you want to continue?" { send "Y\r"; exp_continue }
    "Install Galaxy Camera SDK?" { send "Y\r"; exp_continue }
    eof
}
EOF

# Set library path
export LD_LIBRARY_PATH="/usr/lib:/tmp/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202:$LD_LIBRARY_PATH"

# Install Python dependencies
pip install pillow numpy

echo "Installation complete. You can now run:"
echo "sudo python3 /tmp/Galaxy_Linux_Python_2.0.2106.9041/sample/GxSingleCamMono/GxSingleCamMono.py"
