# Install ImSwitch on Lightsail

```
chmod 600 ~/Downloads/LightsailDefaultKey-eu-central-imswitch.pem
ssh -i ~/Downloads/LightsailDefaultKey-eu-central-imswitch.pem ubuntu@3.71.181.110
sudo -i 
cd /home/ubuntu/Downloads
bash install_lightsail.sh 
```



# Update package lists and install necessary packages
sudo apt-get update 
sudo apt-get install ca-certificates curl gnupg -y 

# Create the directory for Docker's keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Download the Docker GPG key and place it in the keyrings directory
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Ensure the keyring has proper permissions
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package lists again
sudo apt-get update

# Install Docker and its components
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

CODENAME="jammy" # Add the Docker repository to Apt sources 
echo \ "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \ $CODENAME stable" | \ sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# first check if any
swapon -s

# then add some if not
sudo fallocate -l 4G /swapfile 
sudo chmod 600 /swapfile 
sudo mkswap /swapfile 
sudo swapon /swapfile 
sudo cp /etc/fstab /etc/fstab.bak 
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab



# clone github 
cd ~
git clone https://github.com/openUC2/ImSwitchDockerInstall
cd ImSwitchdockerInstall
chmod +x install_all.sh
./install_all.sh


# with caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https -y
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /usr/share/keyrings/caddy-stable-archive-keyring.gpg >/dev/null
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy -y


# sudo nano /etc/caddy/Caddyfile

imswitch.openuc2.com {
reverse_proxy localhost:8001
}

imswitch.openuc2.com:8002 {
reverse_proxy localhost:8003
}

imswitch.openuc2.com:8888 {
reverse_proxy localhost:8889
}




sudo systemctl restart caddy


# start imswitch 

ubuntu@ip-172-26-5-67:~$ sudo systemctl restart caddy
ubuntu@ip-172-26-5-67:~$ sudo docker run -it --rm -p 8001:8001 -p 8003:8002 -p 2222:22 -p 8889:8888 -e HEADLESS=1 -e HTTP_PORT=8001 -e C
ONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 -v ~/:/config -e CONFIG_PATH=/config -e ssl=0  --privilege
d ghcr.io/openuc2/imswitch-noqt-x64:latest 