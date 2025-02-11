# ImSwitch in Docker 

All information have moved here: https://openuc2.github.io/docs/ImSwitch/ImSwitchDocker


# ImSwitch + Docker on Raspi

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

And then 

```bash
sudo docker run -it --rm -p 8001:8001 -p 8002:8002 -p 8888:8888 -e HEADLESS=1  -e HTTP_PORT=8001    -e UPDATE_GIT=1  -e UPDATE_CONFIG=0  -e CONFIG_PATH=/config   -v ~/Downloads:/config --privileged -e DATA_PATH=/dataset  -v /media/uc2/SD2:/dataset  ghcr.io/openuc2/imswitch-noqt-arm64:latest
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

## Install Filegator
```
sudo docker run -d -p 8080:8080 -v my_volume:/home/uc2/ImSwitchConfig/recordings --name filegator filegator/filegator:v7.9.2-multiarch
```
