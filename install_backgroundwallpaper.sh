#!/bin/bash

# Install feh
sudo apt-get install -y feh

# image path
IMAGE_PATH="./IMAGES/uc2_4k.png"

# check if the file exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "File $IMAGE_PATH not found."
    exit 1
fi

# path to the image
ABSOLUTE_IMAGE_PATH=$(cd "$(dirname "$IMAGE_PATH")"; pwd)/$(basename "$IMAGE_PATH")

# set the desktop background
feh --bg-scale "$ABSOLUTE_IMAGE_PATH"

echo "Desktop-Hintergrund was set to $ABSOLUTE_IMAGE_PATH."