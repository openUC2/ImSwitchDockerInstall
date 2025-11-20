#!/bin/bash -eu
sudo apt-get update
sudo apt-get install -y git curl

# in case they don't exist create Download/Desktop folder (e.g. lite)
mkdir -p ~/Downloads
mkdir -p ~/Desktop

ARCH=$(uname -m)

# Set timezone
export TZ=America/Los_Angeles
echo "Setting timezone to $TZ"
#sudo ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" >/etc/timezone

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
    usbutils \
    python3-picamera2

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
conda install -n imswitch311 -y -c conda-forge h5py # numcodecs==0.13.1 scikit-image==0.25.2
conda clean --all -f -y


# Clone the repository and install dependencies
echo "Cloning and installing imSwitch"
git clone https://github.com/openUC2/ImSwitch ~/ImSwitch
cd ~/ImSwitch
git checkout master
source /opt/conda/bin/activate imswitch311 && pip install -e ~/ImSwitch

# Install UC2-REST
echo "Installing UC2-REST"
git clone https://github.com/openUC2/UC2-REST ~/UC2-REST
cd ~/UC2-REST
source /opt/conda/bin/activate imswitch311 && pip install -e ~/UC2-REST

/bin/bash -c "source /opt/conda/bin/activate imswitch311 && \
    CONDA_SITE_PACKAGES=\$(python -c 'import site; print(site.getsitepackages()[0])') && \
    echo '/usr/lib/python3/dist-packages' > \$CONDA_SITE_PACKAGES/system-packages.pth && \
    python -c 'import sys; print(\"Python paths:\"); [print(p) for p in sys.path]'"
source /opt/conda/bin/activate imswitch311 && pip install simplejpeg --force-reinstall --user


# we want psygnal to be installed without binaries - so first remove it - raspi doesn't need this one
# source /opt/conda/bin/activate imswitch && pip uninstall psygnal -y
# source /opt/conda/bin/activate imswitch && pip install psygnal --no-binary :all:
# source /opt/conda/bin/activate imswitch311 && mamba install -c conda-forge --strict-channel-priority numcodecs==0.13.1 -y

# fix numpy
# source /opt/conda/bin/activate imswitch311 && python3 -m pip install numpy==1.26.4 --force-reinstall

# Expose SSH port and HTTP port
#echo "Exposing ports 22, 8002 and 8001 and 8888"
#sudo ufw allow 22
#sudo ufw allow 8001
#sudo ufw allow 8002
#sudo ufw allow 8888

echo "Installation complete. To run the application, use the following command:"
echo "source /opt/conda/bin/activate imswitch311 && python3 ~/ImSwitch/main.py --headless --http-port 8001"

echo "source /opt/conda/bin/activate imswitch311" >>~/.bashrc
