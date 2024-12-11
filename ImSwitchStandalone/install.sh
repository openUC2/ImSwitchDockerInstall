#!/bin/bash

# Ensure you are running this script with root or sudo privileges

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y wget unzip python3 python3-pip build-essential git mesa-utils \
    openssh-server libhdf5-dev nano usbutils sudo vsftpd

# Set Timezone (replace 'America/Los_Angeles' with your preferred timezone if necessary)
sudo timedatectl set-timezone America/Los_Angeles

# Install Miniforge based on architecture
ARCH=$(uname -m)
if [ "$ARCH" == "aarch64" ]; then
    wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh -O /tmp/miniforge.sh
elif [ "$ARCH" == "x86_64" ]; then
    wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Install Miniforge
bash /tmp/miniforge.sh -b -p /opt/conda
rm /tmp/miniforge.sh

# Update PATH environment variable
export PATH="/opt/conda/bin:$PATH"

# Create a conda environment and install required packages
/opt/conda/bin/conda create -y --name imswitch python=3.10
/opt/conda/bin/conda install -n imswitch -y -c conda-forge h5py numcodecs
/opt/conda/bin/conda clean --all -f -y

# Clone the necessary repositories and install Python dependencies
git clone https://github.com/openUC2/imSwitch /tmp/ImSwitch
/opt/conda/bin/conda run -n imswitch pip install -e /tmp/ImSwitch

git clone https://github.com/openUC2/UC2-REST /tmp/UC2-REST
/opt/conda/bin/conda run -n imswitch pip install -e /tmp/UC2-REST

# Clone the ImSwitch config repository
git clone https://github.com/openUC2/ImSwitchConfig /root/ImSwitchConfig

# Always pull the latest version of repositories
cd /tmp/ImSwitch && git pull
/opt/conda/bin/conda run -n imswitch pip install -e /tmp/ImSwitch

cd /tmp/UC2-REST && git pull
/opt/conda/bin/conda run -n imswitch pip install -e /tmp/UC2-REST

# Finished setup message
echo "Installation complete! You can now activate the imswitch environment and run your scripts."
echo "To activate the environment: source /opt/conda/bin/activate imswitch"
