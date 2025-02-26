#!/bin/bash -eu
# sudo docker pull ghcr.io/openuc2/imswitch-noqt-x64:latest
sudo docker pull ghcr.io/openuc2/imswitch-noqt-arm64:latest

# sudo docker run -it --rm -p 8001:8001 -p 8002:8002 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
# sudo docker run -it --rm -p 8001:8001 -p 8003:8002 -p 8889:8888 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 -v ~/:/config -e CONFIG_PATH=/config  --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
