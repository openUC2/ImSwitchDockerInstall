#!/bin/bash
# install_docker_raspi.sh
# Update package lists
sudo apt update -y

# Upgrade installed packages
sudo apt upgrade -y

# Ensure the system is up-to-date
sudo apt-get install ntpdate -y
sudo ntpdate pool.ntp.org

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing Docker..."
    # Install Docker
    curl -sSL https://get.docker.com | sh

    # Add current user to the Docker group
    sudo usermod -aG docker $USER

    # Print message to logout and login again
    echo "Please log out and log back in to apply the Docker group changes."
else
    echo "Docker is already installed. Skipping installation."
fi

# Verify group membership (this will not reflect the changes until you log out and log back in)
groups