#!/usr/bin/env -S bash -eu

# Install RaspAP silently with defaults
mkdir tmp
sudo apt-get update
sudo apt-get install -y git

sudo apt-get install -y hostapd
sudo mkdir -p /etc/raspap/system
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
if ! sudo systemctl start hostapd 2>/dev/null; then
  echo "Warning: couldn't start hostapd. This is expected if you're running in an unbooted container."
fi

if [ "$TERM" = "unknown" ]; then
  echo "Unknown terminal detected. We'll pretend we're a real terminal for the RaspAP installer script!"
  export TERM="dumb"
fi
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
if ! sudo systemctl restart lighttpd 2>/dev/null; then
  echo "Warning: couldn't restart lighttpd. This is expected if you're running in an unbooted container."
fi
if ! sudo systemctl restart hostapd 2>/dev/null; then
  echo "Warning: couldn't restart hostapd. This is expected if you're running in an unbooted container."
fi
if ! sudo systemctl restart dnsmasq 2>/dev/null; then
  echo "Warning: couldn't restart dnsmasq. This is expected if you're running in an unbooted container."
fi
