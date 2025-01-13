#!/bin/sh

set -ex

setup_firewall()
{
    nft flush ruleset
    nft --file /etc/nftables.conf
}

setup_network()
{
    # Load the driver for the Wi-Fi MAC.
    modprobe brcmfmac

    sleep 5

    # Connect to Wi-Fi access point.
    wpa_supplicant -B -Dwext -iwlan0 -c/etc/wpa_supplicant.conf

    # Get an IP address from the access point.
    dhclient wlan0
}

echo "initializing billy pi os"

mount -t debugfs none /sys/kernel/debug

setup_firewall

setup_network

# Start SSH server.
/usr/sbin/sshd

# Start HTTP server.
mkdir /var/log/nginx
nginx
