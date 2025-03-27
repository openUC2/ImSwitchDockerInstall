#!/bin/bash -eu
# install_autostart.sh
# Define variables
START_SCRIPT_PATH="$HOME/Desktop/start_imswitch.sh"
SERVICE_FILE_PATH="/etc/systemd/system/start_imswitch.service"
PYTHON_SCRIPT_PATH="$HOME/detect_drive.py"

# first remove any old entries if available
sudo systemctl stop start_imswitch.service
sudo systemctl disable start_imswitch.service
sudo rm /etc/systemd/system/start_imswitch.service
sudo systemctl daemon-reload


# Create the Python script to detect external drives
cat <<'EOF' >$PYTHON_SCRIPT_PATH
import platform
import subprocess

def detect_external_drives():
    system = platform.system()

    external_drives = []

    if system == "Linux" or system == "Darwin":  # Darwin is the system name for macOS
        # Run 'df' command to get disk usage and filter only mounted devices
        df_result = subprocess.run(['df', '-h'], stdout=subprocess.PIPE)
        output = df_result.stdout.decode('utf-8')

        # Split the output by lines
        lines = output.splitlines()

        # Iterate through each line
        for line in lines:
            # Check if the line contains '/media' or '/Volumes' (common mount points for external drives)
            if '/media/' in line or '/Volumes/' in line:
                # Split the line by spaces and get the mount point
                drive_info = line.split()
                mount_point = " ".join(drive_info[5:])  # Assuming the mount point is at index 5
                # Filter out mount points that contain 'System' for macOS
                if system == "Darwin" and "System" in mount_point:
                    continue
                external_drives.append(mount_point)
    elif system == "Windows":
        # Run 'wmic logicaldisk get caption,description' to get logical disks
        wmic_result = subprocess.run(['wmic', 'logicaldisk', 'get', 'caption,description'], stdout=subprocess.PIPE)
        output = wmic_result.stdout.decode('utf-8')

        # Split the output by lines
        lines = output.splitlines()

        # Iterate through each line
        for line in lines:
            # Check if the line contains 'Removable Disk' (common description for external drives)
            if 'Removable Disk' in line:
                # Split the line by spaces and get the drive letter
                drive_info = line.split()
                drive_letter = drive_info[0]  # Drive letter is the first column
                external_drives.append(drive_letter)

    return external_drives

if __name__ == "__main__":
    drives = detect_external_drives()
    if drives:
        print(drives[0])
    else:
        print("No external drives detected")
EOF

# Make the Python script executable
chmod +x "$PYTHON_SCRIPT_PATH"

# Create the startup script
cat <<'EOF' >$START_SCRIPT_PATH
#!/bin/bash
set -x

LOGFILE=~/start_imswitch.log
DOCKER_LOGFILE=~/docker_imswitch.log
exec > >(tee -a $LOGFILE) 2>&1

echo "Starting IMSwitch Docker container and Chromium"

# Wait for the X server to be available
while ! xset q &>/dev/null; do
  echo "Waiting for X server..."
  sleep 2
done

export DISPLAY=:0

# Detect the external drive
EXTERNAL_DRIVE=$(python3 $HOME/detect_drive.py)

if [ "$EXTERNAL_DRIVE" == "No external drives detected" ]; then
    osascript -e 'display notification "No external drives detected. Using ~/Downloads instead." with title "Warning"'
    echo "No external drives detected. Using ~/Downloads instead."
    EXTERNAL_DRIVE=~/Downloads
fi

# Start Docker container in the background
echo "Running Docker container..."
nohup sudo docker run --rm -d -p 8001:8001 -p 8002:8002 -p 8888:8888 -p 2222:22 \
  -e HEADLESS=1 -e HTTP_PORT=8001 \
  -e DATA_PATH=/dataset \
  -e CONFIG_PATH=/config \
  -e UPDATE_INSTALL_GIT=0 \
  -e UPDATE_CONFIG=0 \
  -v $EXTERNAL_DRIVE:/dataset \
  -v ~/imswitch_docker/imswitch_git:/tmp/ImSwitch-changes \
  -v ~/imswitch_docker/imswitch_pip:/persistent_pip_packages \
  -v ~/:/config \
  --privileged ghcr.io/openuc2/imswitch-noqt-arm64:latest > $DOCKER_LOGFILE 2>&1 & 

# Wait a bit to ensure Docker starts
sleep 30


# Check if Chromium is installed and DISPLAY is set
if command -v chromium-browser &> /dev/null && [ "$DISPLAY" == ":0" ]; then
  echo "Starting Chromium..."
  /usr/bin/chromium-browser --start-fullscreen --ignore-certificate-errors \
    --unsafely-treat-insecure-origin-as-secure=https://0.0.0.0:8001 \
    --unsafely-treat-insecure-origin-as-secure=https://0.0.0.0:8002 \
    --app="data:text/html,<html><body><script>window.location.href='https://0.0.0.0:8001/imswitch/index.html';setTimeout(function(){document.body.style.zoom='0.7';}, 3000);</script></body></html>"
else
  echo "Chromium is not installed or DISPLAY is not set to :0. Skipping Chromium start."
fi

echo "Startup script completed"
EOF

# Make the startup script executable
chmod +x "$START_SCRIPT_PATH"

echo "Startup script created at $START_SCRIPT_PATH and made executable."

# Create the systemd service file
sudo bash -c "cat << EOF > $SERVICE_FILE_PATH
[Unit]
Description=Start IMSwitch Docker and Chromium
After=display-manager.service
Requires=display-manager.service

[Service]
Type=simple
ExecStart=$START_SCRIPT_PATH
User=$USER
Environment=DISPLAY=:0
Restart=on-failure
TimeoutSec=300
StandardOutput=append:~/start_imswitch.service.log
StandardError=append:~/start_imswitch.service.log

[Install]
WantedBy=graphical.target
EOF"

# Reload systemd, enable and start the new service
sudo systemctl enable start_imswitch.service
if sudo systemctl daemon-reload 2>/dev/null; then
    sudo systemctl start start_imswitch.service
else
    echo "Warning: systemd isn't available to start imswitch. This is expected if you're running in an unbooted container."
fi

echo "Systemd service created and enabled to start at boot."
