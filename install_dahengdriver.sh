#!/bin/bash

# Create the udev rules directory
mkdir -p /etc/udev/rules.d

sudo mv /usr/lib/python3.11/EXTERNALLY-MANAGED /usr/lib/python3.11/EXTERNALLY-MANAGED.old


# Download and install the appropriate Hik driver based on architecture
cd /tmp
wget https://dahengimaging.com/downloads/Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz
wget https://dahengimaging.com/downloads/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip
unzip Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip
tar -zxvf Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz

# Set permissions and install the Galaxy camera driver
cd Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202
chmod +x Galaxy_camera.run

# Build and install the Python API
cd /tmp/Galaxy_Linux_Python_2.0.2106.9041/api
python3 setup.py build
python3 setup.py install

# Run the installer script using expect to automate Enter key presses
echo "Y En Y" | sudo /tmp/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202/Galaxy_camera.run

# Set the library path
export LD_LIBRARY_PATH="/usr/lib:/tmp/Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202:$LD_LIBRARY_PATH"

# Install Python packages
pip3 install pillow numpy

# Source the bashrc file
source ~/.bashrc

