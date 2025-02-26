#!/bin/bash -eu

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y wget tar python3 python3-pip

# Download and extract the arm64 build of Vimba
wget https://downloads.alliedvision.com/Vimba_v6.0_ARM64.tgz -O /tmp/Vimba_arm64.tgz
sudo tar -xzf /tmp/Vimba_arm64.tgz -C /opt
rm /tmp/Vimba_arm64.tgz

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y wget tar python3 python3-pip

# Download and extract the ARM64 build of Vimba 6.0
wget https://downloads.alliedvision.com/Vimba_v6.0_ARM64.tgz -O /tmp/Vimba_arm64.tgz
sudo tar -xzf /tmp/Vimba_arm64.tgz -C /opt
sudo rm -f /tmp/Vimba_arm64.tgz

# (Optional) Install the USB transport layer if you have a USB camera.
cd /opt/Vimba_6_0/VimbaUSBTL
if ! sudo ./Install.sh; then
    echo "Warning: USB transport layer could not be installed!"
fi

# (Optional) Install the GigE transport layer if you have a GigE camera:
#   cd /opt/Vimba_6_0/VimbaGigETL
#   sudo ./Install.sh
# Then set the GENICAM_GENTL64_PATH to point to the correct arm_64bit folder under VimbaGigETL.

# Copy VimbaPython source to a writable location (pip needs to build wheels, etc.)
mkdir -p /tmp/VimbaPython
cp -r /opt/Vimba_6_0/VimbaPython/Source/* /tmp/VimbaPython/

# Install VimbaPython globally (or into whichever Python environment is active)
cd /tmp/VimbaPython
sudo python3 -m pip install . --break-system-packages

# Remove the temporary copy
cd /tmp
sudo rm -rf /tmp/VimbaPython

# If you need pymba for older code references (rarely needed with new VimbaPython):
#   sudo python3 -m pip install pymba --break-system-packages

# Example environment variable exports for a 64-bit Raspberry Pi with USB T/L in use
# or for GigE T/L in /opt/Vimba_6_0/VimbaGigETL/CTI/arm_64bit.
# We append them to ~/.bashrc to make them permanent for your user.
# If you prefer them system-wide, put them in /etc/profile.d/xxx.sh
cat >>~/.bashrc <<EOF

# Vimba environment variables (added by install script)
export GENICAM_GENTL64_PATH="/opt/Vimba_6_0/VimbaUSBTL/CTI/arm_64bit:\$GENICAM_GENTL64_PATH"
# If using GigE, comment the line above and uncomment the line below:
# export GENICAM_GENTL64_PATH="/opt/Vimba_6_0/VimbaGigETL/CTI/arm_64bit:\$GENICAM_GENTL64_PATH"

export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:/opt/Vimba_6_0/VimbaC/DynamicLib/linux64"
EOF

echo "============================="
echo " Vimba installation complete"
echo "============================="
echo "Please open a new terminal or 'source ~/.bashrc' so the environment variables take effect."
echo "After that, you should be able to run 'python3' and use VimbaPython." # Export environment variable for GenTL detection (add to ~/.bashrc as needed)

export GENICAM_GENTL64_PATH="${GENICAM_GENTL64_PATH:-}:/opt/Vimba_6_0/VimbaUSBTL/CTI/arm_64bit"

echo "Vimba installation complete."
