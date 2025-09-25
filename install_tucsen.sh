#!/bin/bash
sudo apt-get install libudev1
sudo apt-get install libudev-dev

cd TUCAM

chmod +x install.sh
sudo ./install.sh