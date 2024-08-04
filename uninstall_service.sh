#!/bin/bash

# Define variables
START_SCRIPT_PATH="$HOME/start_imswitch.sh"
SERVICE_FILE_PATH="/etc/systemd/system/start_imswitch.service"
LOG_FILE_PATH="$HOME/start_imswitch.log"
SERVICE_LOG_FILE_PATH="$HOME/start_imswitch.service.log"

# Stop and disable the systemd service
echo "Stopping and disabling the service..."
sudo systemctl stop start_imswitch.service
sudo systemctl disable start_imswitch.service

# Remove the systemd service file
if [ -f "$SERVICE_FILE_PATH" ]; then
    echo "Removing systemd service file..."
    sudo rm "$SERVICE_FILE_PATH"
else
    echo "Systemd service file not found."
fi

# Remove the startup script
if [ -f "$START_SCRIPT_PATH" ]; then
    echo "Removing startup script..."
    rm "$START_SCRIPT_PATH"
else
    echo "Startup script not found."
fi

# Remove log files
if [ -f "$LOG_FILE_PATH" ]; then
    echo "Removing log file..."
    rm "$LOG_FILE_PATH"
else
    echo "Log file not found."
fi

if [ -f "$SERVICE_LOG_FILE_PATH" ]; then
    echo "Removing service log file..."
    rm "$SERVICE_LOG_FILE_PATH"
else
    echo "Service log file not found."
fi

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Uninstallation complete."
