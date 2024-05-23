#!/bin/sh

echo "initializing billy pi os"

# Initialize logging.
syslogd

# Load the driver for the Wi-Fi MAC.
modprobe brcmfmac

sleep 5

# Connect to Wi-Fi access point.
wpa_supplicant -B -Dwext -iwlan0 -c/etc/wpa_supplicant.conf

# Get an IP address from the access point.
dhclient wlan0

# Start SSH server.
/usr/bin/ssh-keygen -A
/usr/sbin/sshd
