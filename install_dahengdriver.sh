#!/bin/bash -eu
# install_dahengdriver.sh

sudo apt-get install -y python3 python3-pip

# Create the udev rules directory
mkdir -p /etc/udev/rules.d

sudo mv /usr/lib/python3.11/EXTERNALLY-MANAGED /usr/lib/python3.11/EXTERNALLY-MANAGED.old

# Download and install the appropriate Daheng driver based on architecture
cd /tmp

# Auto-detect architecture and set appropriate download URLs
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    DAHENG_ZIP="Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip"
    DAHENG_URL="https://github.com/openUC2/ImSwitchDockerInstall/releases/download/imswitch-master/${DAHENG_ZIP}"
    DAHENG_DIR="Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202"
elif [ "$ARCH" = "x86_64" ]; then
    DAHENG_ZIP="Galaxy_Linux-x86_Gige-U3_32bits-64bits_2.4.2503.9201.zip"
    DAHENG_URL="https://dahengimaging.com/downloads/${DAHENG_ZIP}"
    DAHENG_DIR="Galaxy_Linux-x86_Gige-U3_32bits-64bits_2.4.2503.9201"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Download Python API (same for both architectures)
wget https://dahengimaging.com/downloads/Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz

# Download architecture-specific driver
wget "$DAHENG_URL"

# Extract files
unzip "$DAHENG_ZIP"
tar -zxvf Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz

# Set permissions and install the Galaxy camera driver
cd "$DAHENG_DIR"
chmod +x Galaxy_camera.run

# Build and install the Python API
cd /tmp/Galaxy_Linux_Python_2.0.2106.9041/api
python3 setup.py build
sudo python3 setup.py install

# Run the installer script using expect to automate Enter key presses
echo "Y En Y" | sudo "/tmp/$DAHENG_DIR/Galaxy_camera.run"

# Set the library path
export LD_LIBRARY_PATH="/usr/lib:/tmp/$DAHENG_DIR:${LD_LIBRARY_PATH:-}"

# Install Python packages
pip3 install pillow numpy

# Source the bashrc file
source ~/.bashrc
