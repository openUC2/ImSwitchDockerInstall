#!/bin/bash

cd /tmp 
wget https://www.hikrobotics.com/cn2/source/support/software/MVS_STD_GML_V2.1.2_231116.zip 
unzip MVS_STD_GML_V2.1.2_231116.zip 
echo "Install Hik Driver"
sudo dpkg -i MVS-2.1.2_aarch64_20231116.deb
cd /opt/MVS/Samples/aarch64/Python/
cp GrabImage/GrabImage.py MvImport/GrabImage.py
export MVCAM_COMMON_RUNENV=/opt/MVS/lib 
export LD_LIBRARY_PATH=/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH 
    