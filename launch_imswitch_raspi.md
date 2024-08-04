
Run as sudo (e.g. `sudo -s`)
```bash
cd ~/Downloads
git clone https://github.com/openUC2/ImSwitchDockerInstall
cd ImSwitchDockerInstall
echo "Install Docker"
chmod +x install_docker_raspi.sh
./install_docker_raspi.sh
echo "Pull and Install Docker Image"
chmod +x pull_and_run.sh
./pull_and_run.sh
```

or simply

```bash
cd ~/Downloads
git clone https://github.com/openUC2/ImSwitchDockerInstall
cd ImSwitchDockerInstall
chmod +x install_all.sh
./install_all.sh
```

And then 

```bash
sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
```qq