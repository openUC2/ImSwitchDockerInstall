#!/bin/bash
# Define the desktop path
DESKTOP_PATH=~/Desktop

# Create the update script
echo "#!/bin/bash
# Pull the latest version of the docker container
docker pull ghcr.io/openuc2/imswitch-noqt-x64:latest
" > "$DESKTOP_PATH/update_docker_container.sh"

# Make the update script executable
chmod +x "$DESKTOP_PATH/update_docker_container.sh"

# Create the launch script
echo "#!/bin/bash
#!/bin/bash
# Run the docker container with specified parameters
sudo docker run -it --rm -p 8001:8001 -p 2222:22
-e CONFIG_PATH=/config
-e DATA_PATH=/dataset
-v ~/Documents/imswitch_docker/imswitch_git:/tmp/ImSwitch-changes
-v ~/Documents/imswitch_docker/imswitch_pip:/persistent_pip_packages
-v ~/Downloads:/dataset
-v ~/:/config
-e HEADLESS=1
-e HTTP_PORT=8001
-e UPDATE_INSTALL_GIT=0
-e UPDATE_CONFIG=0
--privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
" > "$DESKTOP_PATH/launch_docker_container.sh"

# Make the launch script executable
chmod +x "$DESKTOP_PATH/launch_docker_container.sh"

# Inform the user
echo "Scripts created on the desktop: update_docker_container.sh and launch_docker_container.sh"
