#!/bin/bash -eu
sudo apt-get update
sudo apt-get install -y git curl

# in case they don't exist create Download/Desktop folder (e.g. lite)
mkdir -p ~/Downloads
mkdir -p ~/Desktop

# Set timezone
export TZ=America/Los_Angeles
echo "Setting timezone to $TZ"
sudo ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" >/etc/timezone

# Update and install necessary dependencies
echo "Updating system and installing dependencies"
sudo apt-get update && sudo apt-get install -y \
    wget \
    unzip \
    python3 \
    python3-pip \
    build-essential \
    git \
    mesa-utils \
    openssh-server \
    libhdf5-dev \
    usbutils

# Clean up apt caches
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
# Install Miniforge
echo "Installing Miniforge"
if [ "$ARCH" = "aarch64" ]; then
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh -O /tmp/miniforge.sh
elif [ "$ARCH" = "x86_64" ]; then
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh
fi
sudo bash /tmp/miniforge.sh -b -p /opt/conda
rm /tmp/miniforge.sh

# Update PATH environment variable
echo "Updating PATH"
export PATH=/opt/conda/bin:$PATH

# Create conda environment and install packages
echo "Creating conda environment and installing packages"
conda create -y --name imswitch311 python=3.11
conda install -n imswitch311 -y -c conda-forge h5py numcodecs scikit-image
conda clean --all -f -y

# Clone the config folder
echo "Cloning ImSwitchConfig"
git clone https://github.com/openUC2/ImSwitchConfig ~/ImSwitchConfig

# Clone the repository and install dependencies
echo "Cloning and installing imSwitch"
git clone https://github.com/openUC2/imSwitch ~/ImSwitch
cd ~/ImSwitch
git checkout master
source /opt/conda/bin/activate imswitch311 && pip install -e ~/ImSwitch

# Install UC2-REST
echo "Installing UC2-REST"
git clone https://github.com/openUC2/UC2-REST ~/UC2-REST
cd ~/UC2-REST
source /opt/conda/bin/activate imswitch311 && pip install -e ~/UC2-REST

# we want psygnal to be installed without binaries - so first remove it - raspi doesn't need this one
# source /opt/conda/bin/activate imswitch && pip uninstall psygnal -y
# source /opt/conda/bin/activate imswitch && pip install psygnal --no-binary :all:

# fix the version of OME-ZARR
source /opt/conda/bin/activate imswitch311 && pip install ome-zarr==0.9.0
source /opt/conda/bin/activate imswitch311 && conda install -c conda-forge --strict-channel-priority numpy scikit-image==0.19.3 -y

# fix numpy
source /opt/conda/bin/activate imswitch311 && python3 -m pip install numpy==1.26.4

# Expose SSH port and HTTP port
echo "Exposing ports 22, 8002 and 8001 and 8888"
sudo ufw allow 22
sudo ufw allow 8001
sudo ufw allow 8002
sudo ufw allow 8888

echo "Installation complete. To run the application, use the following command:"
echo "source /opt/conda/bin/activate imswitch311 && python3 ~/ImSwitch/main.py --headless --http-port 8001"

echo "source /opt/conda/bin/activate imswitch311" >>~/.bashrc
