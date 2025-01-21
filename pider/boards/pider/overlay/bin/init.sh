#!/bin/sh

set -ex

setup_firewall()
{
    nft flush ruleset
    nft --file /etc/nftables.conf
}

setup_network()
{
    # The brcmfmac module (Wi-Fi MAC) takes some time to initialize. Let's wait
    # for the interface to show up.
    while ! grep -q wlan0 /proc/net/dev
    do
        usleep 100000
    done

    dhcp_interfaces=eth0

    # If the wpa_supplicant config exists, connected to the Wi-Fi access point.
    if [ -e /etc/wpa_supplicant.conf ]
    then
        wpa_supplicant -dd -B -D wext -i wlan0 -c /etc/wpa_supplicant.conf
        dhcp_interfaces="$dhcp_interfaces wlan0"
    fi

    # Get IP address on all DHCP interfaces.
    dhclient -v $dhcp_interfaces
}

setup_ssh_server()
{
    # Generate some host keys.
    ssh-keygen -A

    # Start SSH server.
    /usr/sbin/sshd
}

setup_https_server()
{
    # Start HTTP server.
    mkdir /var/log/nginx
    nginx
}

echo "initializing pider"

mount -t debugfs none /sys/kernel/debug

setup_firewall

setup_network

setup_ssh_server

setup_https_server
