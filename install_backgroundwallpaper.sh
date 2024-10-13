#!/bin/bash

# Pfad zum Bild
IMAGE_PATH="./IMAGES/uc2_4.png"

# Überprüfen, ob die Bilddatei existiert
if [ ! -f "$IMAGE_PATH" ]; then
    echo "File $IMAGE_PATH not found."
    exit 1
fi

# Absoluten Pfad zum Bild erhalten
ABSOLUTE_IMAGE_PATH=$(cd "$(dirname "$IMAGE_PATH")"; pwd)/$(basename "$IMAGE_PATH")

# AppleScript-Befehl zum Setzen des Desktop-Hintergrunds
osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$ABSOLUTE_IMAGE_PATH\""

echo "Desktop-Background was set to $ABSOLUTE_IMAGE_PATH."