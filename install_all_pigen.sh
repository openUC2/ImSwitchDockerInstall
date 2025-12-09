#!/bin/bash -eu
# install requirements
sudo apt-get update

# in case they don't exist create Download/Desktop folder (e.g. lite)
mkdir ~/Downloads
mkdir ~/Desktop

cd ~/Downloads/ImSwitchDockerInstall
echo "Install Docker"
chmod +x install_docker_raspi.sh
./install_docker_raspi.sh


mkdir -p /etc/udev/rules.d
for file in /usr/lib/python*/EXTERNALLY-MANAGED; do
    sudo mv "$file" "$file.old"
done

# Download and install the appropriate Hik/daheng driver based on architecture
cd /tmp

# Auto-detect architecture for Daheng driver
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    DAHENG_ZIP="Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip"
    DAHENG_URL="https://github.com/openUC2/ImSwitchDockerInstall/releases/download/imswitch-master/${DAHENG_ZIP}"
elif [ "$ARCH" = "x86_64" ]; then
    DAHENG_ZIP="Galaxy_Linux-x86_Gige-U3_32bits-64bits_2.4.2503.9201.zip"
    DAHENG_URL="https://dahengimaging.com/downloads/${DAHENG_ZIP}"
else
    # Fallback to ARM version
    DAHENG_ZIP="Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202.zip"
    DAHENG_URL="https://github.com/openUC2/ImSwitchDockerInstall/releases/download/imswitch-master/${DAHENG_ZIP}"
fi

wget https://dahengimaging.com/downloads/Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz
wget "$DAHENG_URL"
cd /tmp
wget https://www.hikrobotics.com/en2/source/vision/video/2024/9/3/MVS_STD_V3.0.1_240902.zip

####### THIS IS EXECUTED ON FIRST BOOT!

#!/bin/bash -e
#
# This script runs inside chroot during pi-gen build. It merely
# drops a 'first_boot_setup.sh' script and 'first_boot_setup.service'
# so that the real driver installation and Docker steps happen
# on the Pi itself at first boot.

# --------------------------------------------------------------------------
# 1) Create /usr/local/bin/first_boot_setup.sh
# --------------------------------------------------------------------------
cat <<'EOF' >/usr/local/bin/first_boot_setup.sh
#!/bin/bash -e
#
# first_boot_setup.sh
# Runs once on the Pi's first actual boot to install the driver
# and set up desktop icons/autostart scripts. After finishing,
# it disables itself so it won't run on subsequent boots.

#--------------------------------------------
# STEP A.1: Install MVS driver (auto-detect architecture) at FIRST BOOT
#--------------------------------------------
echo "Installing MVS driver..."
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    MVS_DEB="/tmp/MVS-3.0.1_aarch64_20240902.deb"
    MVS_SAMPLE_PATH="aarch64"
elif [ "$ARCH" = "x86_64" ]; then
    MVS_DEB="/tmp/MVS-3.0.1_x86_64_20240902.deb"
    MVS_SAMPLE_PATH="64"
else
    echo "Unsupported architecture: $ARCH"
    MVS_DEB="/tmp/MVS-3.0.1_aarch64_20240902.deb"  # fallback
    MVS_SAMPLE_PATH="aarch64"
fi

if [ -f "$MVS_DEB" ]; then
    dpkg -i "$MVS_DEB" || true
fi

echo "Copying GrabImage.py..."
if [ -d "/opt/MVS/Samples/${MVS_SAMPLE_PATH}/Python/" ]; then
  cd "/opt/MVS/Samples/${MVS_SAMPLE_PATH}/Python/"
  cp GrabImage/GrabImage.py MvImport/GrabImage.py || true
fi

# Set environment variables for the camera driver
# (To persist across reboots, append them to /etc/profile or similar)
echo 'export MVCAM_COMMON_RUNENV=/opt/MVS/lib' >> /etc/profile
echo 'export LD_LIBRARY_PATH=/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH' >> /etc/profile

#--------------------------------------------
# STEP A.2: Install Daheng driver (arm64) at FIRST BOOT
#--------------------------------------------

cd /tmp
unzip "$DAHENG_ZIP"
tar -zxvf Galaxy_Linux_Python_2.0.2106.9041.tar_1.gz

# Determine directory name based on architecture
if [ "$ARCH" = "aarch64" ]; then
    DAHENG_DIR="Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202"
elif [ "$ARCH" = "x86_64" ]; then
    DAHENG_DIR="Galaxy_Linux-x86_Gige-U3_32bits-64bits_2.4.2503.9201"
else
    DAHENG_DIR="Galaxy_Linux-armhf_Gige-U3_32bits-64bits_1.5.2303.9202"  # fallback
fi

# Set permissions and install the Galaxy camera driver
cd "$DAHENG_DIR"
chmod +x Galaxy_camera.run

# Build and install the Python API
cd /tmp/Galaxy_Linux_Python_2.0.2106.9041/api
python3 setup.py build
python3 setup.py install

# Run the installer script using expect to automate Enter key presses
echo "Y En Y" | sudo "/tmp/$DAHENG_DIR/Galaxy_camera.run"

# Set the library path
export LD_LIBRARY_PATH="/usr/lib:/tmp/$DAHENG_DIR:$LD_LIBRARY_PATH"

# Install Python packages
pip3 install pillow numpy

# Source the bashrc file
source ~/.bashrc



#--------------------------------------------
# STEP B: Create Desktop + Downloads folders
# (Assuming default user is 'pi'. Adjust as needed.)
#--------------------------------------------
USER_HOME="/home/pi"
DESKTOP_PATH="$USER_HOME/Desktop"
DOWNLOADS_PATH="$USER_HOME/Downloads"

mkdir -p "$DESKTOP_PATH"
mkdir -p "$DOWNLOADS_PATH"
chown -R pi:pi "$DESKTOP_PATH" "$DOWNLOADS_PATH"

#--------------------------------------------
# STEP C: Place your Docker scripts on Desktop (but do NOT pull Docker yet)
#--------------------------------------------
cat << 'SCRIPT1' > "$DESKTOP_PATH/update_docker_container.sh"
#!/bin/bash
# Pull the latest version of the docker container
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/')
sudo docker pull ghcr.io/openuc2/imswitch-noqt:latest
SCRIPT1

cat << 'SCRIPT2' > "$DESKTOP_PATH/launch_docker_container.sh"
#!/bin/bash
# Run the docker container with specified parameters
docker run -it --rm \
  -p 8001:8001 -p 8002:8002 -p 8003:8003 -p 8888:8888 -p 2222:22 \
  -e CONFIG_PATH=/config \
  -e DATA_PATH=/dataset \
  -v ~/Documents/imswitch_docker/imswitch_git:/tmp/ImSwitch-changes \
  -v ~/Documents/imswitch_docker/imswitch_pip:/persistent_pip_packages \
  -v ~/Downloads:/dataset \
  -v ~/:/config \
  -e HEADLESS=1 \
  -e HTTP_PORT=8001 \
  -e UPDATE_INSTALL_GIT=0 \
  -e UPDATE_CONFIG=0 \
  --privileged ghcr.io/openuc2/imswitch-noqt:latest
SCRIPT2

chmod +x "$DESKTOP_PATH/update_docker_container.sh" "$DESKTOP_PATH/launch_docker_container.sh"
chown pi:pi "$DESKTOP_PATH/"*.sh

#--------------------------------------------
# STEP D: Create detect_drive.py in pi's home
#--------------------------------------------
DETECT_PY="$USER_HOME/detect_drive.py"
cat << 'PYEOF' > "$DETECT_PY"
import platform
import subprocess

def detect_external_drives():
    system = platform.system()
    external_drives = []

    if system == "Linux" or system == "Darwin":
        df_result = subprocess.run(['df', '-h'], stdout=subprocess.PIPE)
        output = df_result.stdout.decode('utf-8')
        lines = output.splitlines()
        for line in lines:
            if '/media/' in line or '/Volumes/' in line:
                drive_info = line.split()
                mount_point = " ".join(drive_info[5:])
                if system == "Darwin" and "System" in mount_point:
                    continue
                external_drives.append(mount_point)
    elif system == "Windows":
        wmic_result = subprocess.run(['wmic', 'logicaldisk', 'get', 'caption,description'], stdout=subprocess.PIPE)
        output = wmic_result.stdout.decode('utf-8')
        lines = output.splitlines()
        for line in lines:
            if 'Removable Disk' in line:
                drive_info = line.split()
                drive_letter = drive_info[0]
                external_drives.append(drive_letter)
    return external_drives

if __name__ == "__main__":
    drives = detect_external_drives()
    if drives:
        print(drives[0])
    else:
        print("No external drives detected")
PYEOF

chmod +x "$DETECT_PY"
chown pi:pi "$DETECT_PY"

#--------------------------------------------
# STEP E: Create the start_imswitch.sh + systemd service
#--------------------------------------------
START_SCRIPT_PATH="$USER_HOME/Desktop/start_imswitch.sh"
cat << 'EOSH' > "$START_SCRIPT_PATH"
#!/bin/bash
set -x
LOGFILE=~/start_imswitch.log
DOCKER_LOGFILE=~/docker_imswitch.log
exec > >(tee -a $LOGFILE) 2>&1


EXTERNAL_DRIVE=$(python3 ~/detect_drive.py)
if [ "$EXTERNAL_DRIVE" == "No external drives detected" ]; then
    echo "No external drives detected. Using ~/Downloads instead."
    EXTERNAL_DRIVE=~/Downloads
fi

echo "Running Docker container..."
nohup docker run --rm -d -p 8001:8001 -p 8002:8002 -p 8888:8888 -p 2222:22 \
  -e HEADLESS=1 -e HTTP_PORT=8001 \
  -e DATA_PATH=/dataset \
  -e CONFIG_PATH=/config \
  -e UPDATE_INSTALL_GIT=0 \
  -e UPDATE_CONFIG=0 \
  -v $EXTERNAL_DRIVE:/dataset \
  -v ~/imswitch_docker/imswitch_git:/tmp/ImSwitch-changes \
  -v ~/imswitch_docker/imswitch_pip:/persistent_pip_packages \
  -v ~/:/config \
  --privileged ghcr.io/openuc2/imswitch-noqt:latest > $DOCKER_LOGFILE 2>&1 &

echo "Startup script completed"
EOSH

chmod +x "$START_SCRIPT_PATH"
chown pi:pi "$START_SCRIPT_PATH"

SYSTEMD_FILE_PATH="/etc/systemd/system/start_imswitch.service"
cat << EOSVC > "$SYSTEMD_FILE_PATH"
[Unit]
Description=Start IMSwitch Docker
After=display-manager.service
Requires=display-manager.service

[Service]
Type=simple
ExecStart=$START_SCRIPT_PATH
User=pi
Environment=DISPLAY=:0
Restart=on-failure
TimeoutSec=300

[Install]
WantedBy=graphical.target
EOSVC

# Enable the start_imswitch service on the final system
systemctl daemon-reload
systemctl enable start_imswitch.service

#--------------------------------------------
# STEP F: Self-disable this first_boot_setup on completion
#--------------------------------------------
echo "Disabling 'first_boot_setup.service' so it won't run again."
systemctl disable first_boot_setup.service
rm -f /etc/systemd/system/first_boot_setup.service
rm -f /usr/local/bin/first_boot_setup.sh

echo "First-boot setup complete. Reboot to apply changes."
exit 0
EOF

# Make it executable
chmod +x /usr/local/bin/first_boot_setup.sh

# --------------------------------------------------------------------------
# 2) Create /etc/systemd/system/first_boot_setup.service
#    so that script runs once on real Pi, after boot
# --------------------------------------------------------------------------
cat <<'SERVICEOF' >/etc/systemd/system/first_boot_setup.service
[Unit]
Description=Install MVS driver & set up IMSwitch on first boot
After=multi-user.target
Requires=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/first_boot_setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICEOF

# Enable it so it runs at next real boot
systemctl enable first_boot_setup.service

# Done. We do NOT actually install or start the driver in chroot.
exit 0
