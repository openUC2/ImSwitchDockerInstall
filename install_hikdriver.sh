#!/bin/bash

cd /tmp 
#wget https://www.hikrobotics.com/cn2/source/support/software/MVS_STD_GML_V2.1.2_231116.zip 
wget https://www.hikrobotics.com/en2/source/vision/video/2024/9/3/MVS_STD_V3.0.1_240902.zip
#unzip MVS_STD_GML_V2.1.2_231116.zip 
unzip MVS_STD_V3.0.1_240902.zip
echo "Install Hik Driver"
sudo dpkg -i MVS-3.0.1_aarch64_20240902.deb
cd /opt/MVS/Samples/aarch64/Python/
cp GrabImage/GrabImage.py MvImport/GrabImage.py
export MVCAM_COMMON_RUNENV=/opt/MVS/lib 
export LD_LIBxRARY_PATH=/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH 
