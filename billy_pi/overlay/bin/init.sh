#!/bin/sh

echo "Initializing Billy Pi OS"

# Initialize logging.
syslogd

# Connect to Wi-Fi access point.
wpa_supplicant -B -Dwext -iwlan0 -c/etc/wpa_supplicant.conf

# Get an IP address from the access point.
dhclient wlan0
