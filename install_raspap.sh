#!/usr/bin/env -S bash -eu

# Install RaspAP silently with defaults
mkdir tmp
sudo apt-get update
sudo apt-get install -y git

sudo apt-get install -y hostapd
sudo mkdir -p /etc/raspap/system
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

curl -sL https://install.raspap.com | bash -s -- --yes --wireguard 0 --adblock 0 --openvpn 0 --restapi 1 --update

# Generate your custom SSID with random digits
SSID="openUC2-$(tr -dc 0-9 </dev/urandom | head -c 6)"
echo "Using SSID: $SSID"

# Update hostapd settings with new SSID and pass
sudo sed -i "s/^ssid=.*/ssid=$SSID/g" /etc/hostapd/hostapd.conf
sudo sed -i "s/^wpa_passphrase=.*/wpa_passphrase=youseetoo/g" /etc/hostapd/hostapd.conf

# Enable captive portal in RaspAP’s config
# This is controlled by /etc/lighttpd/conf-available/10-raspap-captiveportal.conf
# and a few RaspAP config files. The simplest method:
sudo raspi-config nonint do_hostname "raspberrypi" # optional, just an example usage
sudo cp /etc/lighttpd/conf-available/10-raspap-captiveportal.conf /etc/lighttpd/conf-enabled/

# Redirect all requests to your custom page. Adjust as needed.
#    By default, 10-raspap-captiveportal.conf might redirect to /captiveportal/index.php
#    You can override or replace the existing rule. For example:
sudo sed -i 's|\(url.redirect = \).*|\1("/.*" => "http://10.3.141.1:8001/imsiwtch/index.html")|g' \
  /etc/lighttpd/conf-available/10-raspap-captiveportal.conf

# 6) Restart services to apply changes
sudo systemctl restart lighttpd
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq
