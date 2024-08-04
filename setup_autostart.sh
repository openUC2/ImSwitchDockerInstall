#!/bin/bash

# Define variables
START_SCRIPT_PATH="$HOME/start_imswitch.sh"
SERVICE_FILE_PATH="/etc/systemd/system/start_imswitch.service"

# Create the startup script
cat << 'EOF' > $START_SCRIPT_PATH
#!/bin/bash
set -x

LOGFILE=~/start_imswitch.log
exec > >(tee -a $LOGFILE) 2>&1

echo "Starting IMSwitch Docker container and Chromium"

# Wait for the X server to be available
while ! xset q &>/dev/null; do
  echo "Waiting for X server..."
  sleep 2
done

export DISPLAY=:0

# need to perform:
# sudo docker run -it --rm -p 8002:8001  -e HEADLESS=1  -e HTTP_PORT=8001  -e UPDATE_GIT=1  
# -e UPDATE_CONFIG=0  --privileged -e DATA_PATH=/dataset -e CONFIG_PATH=/config -v /media/uc2/SD2/:/dataset
# -v /home/uc2/:/config  ghcr.io/openuc2/imswitch-noqt-x64:latest
# Start Docker container in the background
echo "Running Docker container..."
nohup sudo docker run --rm -d -p 8001:8001 -p 2222:22 \
  -e HEADLESS=1 -e HTTP_PORT=8001 \
  -e DATA_PATH=/dataset \
  -e CONFIG_PATH=/config \
  -e CONFIG_FILE=example_uc2_hik_flowstop.json \
  -e UPDATE_GIT=1 -e UPDATE_CONFIG=0 \
  -v /media/uc2/SD2/:/dataset \
  -v /home/uc2/:/config \
  --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest &


/home/uc2/ImSwitchConfig
# Wait a bit to ensure Docker starts
sleep 10

# Start Chromium
echo "Starting Chromium..."
/usr/bin/chromium-browser --start-fullscreen --ignore-certificate-errors \
  --unsafely-treat-insecure-origin-as-secure=https://0.0.0.0:8001 \
  --app="data:text/html,<html><body><script>window.location.href='https://0.0.0.0:8001/imswitch/index.html';setTimeout(function(){document.body.style.zoom='0.7';}, 3000);</script></body></html>"

echo "Startup script completed"
EOF

# Make the startup script executable
chmod +x $START_SCRIPT_PATH

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
StandardOutput=append:/home/uc2/start_imswitch.service.log
StandardError=append:/home/uc2/start_imswitch.service.log

[Install]
WantedBy=graphical.target
EOF"

# Reload systemd, enable and start the new service
sudo systemctl daemon-reload
sudo systemctl enable start_imswitch.service
sudo systemctl start start_imswitch.service

echo "Systemd service created and enabled to start at boot."
