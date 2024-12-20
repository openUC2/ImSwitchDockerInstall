#!/bin/bash

# image path
IMAGE_PATH="./IMAGES/uc2_4k.png"  # Provide the correct absolute path to your image

# Install wallpaper directory
WALLPAPER_ROOT="/usr/share/uc2-wallpaper"
sudo install -d "${WALLPAPER_ROOT}"

# Install default wallpaper
WALLPAPER_PATH="${WALLPAPER_ROOT}/uc2_4k.png"
sudo install -v -m 644 "$IMAGE_PATH" "${WALLPAPER_PATH}"

# Set default wallpaper
TARGET_KEY="wallpaper"
CONFIG_FILE_0="/etc/xdg/pcmanfm/LXDE-pi/desktop-items-0.conf"
CONFIG_FILE_1="/etc/xdg/pcmanfm/LXDE-pi/desktop-items-1.conf"

sudo sed -i "/${TARGET_KEY}=/ s|=.*|=${WALLPAPER_PATH}|" "$CONFIG_FILE_0"
sudo sed -i "/${TARGET_KEY}=/ s|=.*|=${WALLPAPER_PATH}|" "$CONFIG_FILE_1"

echo "Desktop wallpaper has been set to ${WALLPAPER_PATH}."
