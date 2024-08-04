## installing the service 

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
sudo docker run -it --rm -p 8001:8001  -e HEADLESS=1  -e HTTP_PORT=8001    -e UPDATE_GIT=1  -e UPDATE_CONFIG=0  -e CONFIG_PATH=/config   -v ~/Downloads:/config --privileged -e DATA_PATH=/dataset  -v /media/uc2/SD2:/dataset  ghcr.io/openuc2/imswitch-noqt-x64:latest
```

- `-v ~/Downloads:/config` corresponds to the Github ImSwitchConfig folder that was downloaded and used for ImSwitch
- `-v /media/uc2/SD2:/dataset` corresponds to the folder where we will save the data to


## uninstalling the service

```bash
cd ~/Downloads/ImSwitchDockerInstall
chmod +x uninstall_service.sh
./uninstall_service.sh
```