# ImSwitch in Docker 

All information have moved here: https://openuc2.github.io/docs/ImSwitch/ImSwitchDocker

## Architecture Support

This installation package now supports both ARM64 (Raspberry Pi) and AMD64 (x86_64) architectures automatically. The scripts will auto-detect your system architecture and use the appropriate Docker image.

# ImSwitch + Docker on Raspi/AMD64

This installs the full package:
- Docker
- ImSwitch in Docker
- Drivers
- install_autostart on Raspi with autoupdate
   
Run as sudo (e.g. `sudo -s`)
```bash
cd ~/Downloads
git clone https://github.com/openUC2/ImSwitchDockerInstall
cd ImSwitchDockerInstall
chmod +x install_all.sh
./install_all.sh
```

## Using Docker Compose

For easier management, you can use Docker Compose:

```bash
# Set architecture and start services
./docker-compose.sh up -d

# Or manually set architecture
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/') docker-compose up -d
```

## Manual Docker Run

And then 

```bash
# Auto-detect architecture (ARM64 or AMD64)
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/')
sudo docker run -it --rm -p 8001:8001 -p 8002:8002 -p 8888:8888 -e HEADLESS=1  -e HTTP_PORT=8001    -e UPDATE_GIT=1  -e UPDATE_CONFIG=0  -e CONFIG_PATH=/config   -v ~/Downloads:/config --privileged -e DATA_PATH=/dataset  -v /media/uc2/SD2:/dataset  ghcr.io/openuc2/imswitch-noqt:latest
```

- `-v ~/Downloads:/config` corresponds to the Github ImSwitchConfig folder that was downloaded and used for ImSwitch
- `-v /media/uc2/SD2:/dataset` corresponds to the folder where we will save the data to
- 
## Connect to Wifi 

use `nmtui` for discovering and connecting to Wifi signals nearby.

## change external drive

open the file under `~/Desktop/start_imswitch.sh` and replace the line `-v /media/uc2/SD2:/dataset` with the usb drive that you can detect with `df -h`

## uninstalling the service

```bash
cd ~/Downloads/ImSwitchDockerInstall
chmod +x uninstall_service.sh
./uninstall_service.sh
```

## Quickstart Docker on AMD/ARM

```bash
# Auto-detect architecture and run appropriate image
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/')
sudo docker run -it --rm -p 8001:8001 -p 8003:8002 -p 2222:22 -p 8889:8888 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 -v ~/:/config -e CONFIG_PATH=/config -e ssl=0 --privileged ghcr.io/openuc2/imswitch-noqt:latest
```

Manual selection (if needed):
```bash
# Universal image (works for all architectures)
sudo docker run -it --rm -p 8001:8001 -p 8003:8002 -p 2222:22 -p 8889:8888 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 -v ~/:/config -e CONFIG_PATH=/config -e ssl=0 --privileged ghcr.io/openuc2/imswitch-noqt:latest
```


## Manually Check if service is working

```
sudo systemctl start start_imswitch.service
sudo journalctl -f -u start_imswitch.service
```

## Remove the Autostart service again

```
sudo systemctl stop start_imswitch.service
sudo systemctl disable start_imswitch.service
sudo rm /etc/systemd/system/start_imswitch.service
sudo systemctl daemon-reload
```