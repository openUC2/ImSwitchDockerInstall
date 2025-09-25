#!/bin/bash

folder="/etc/tucam/"

if [ ! -d "$folder" ]; then
  mkdir "$folder"
fi

# copy the tucsen usb camera config file
cp tuusb.conf /etc/tucam

# copy the tucsen camera libraries
cp libTUCam.so /usr/lib
cp libTUCam.so.1 /usr/lib
cp libTUCam.so.1.0 /usr/lib
cp libTUCam.so.1.0.0 /usr/lib
