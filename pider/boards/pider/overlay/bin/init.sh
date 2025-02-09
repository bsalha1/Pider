#!/bin/sh

set -ex

setup_firewall()
{
    nft flush ruleset
    nft --file /etc/nftables.conf
}

setup_network()
{
    # Assign loopback address.
    ip addr add 127.0.0.1/8 dev lo
    ip link set lo up

    dhcp_interfaces=eth0

    # If the wpa_supplicant config exists, connected to the Wi-Fi access point.
    if [ -e /etc/wpa_supplicant.conf ]
    then
        # The brcmfmac module (Wi-Fi MAC) takes some time to initialize. Let's wait for the
        # interface to show up.
        while ! grep -q wlan0 /proc/net/dev
        do
            usleep 100000
        done

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

setup_livestream()
{
    # The Raspberry Pi 5 contains a custom Image Signal Processor pipeline called PiSP (source https://datasheets.raspberrypi.com/camera/raspberry-pi-image-signal-processor-specification.pdf)
    #
    # The realtime front end receives streaming pixel data from the camera, performs some processing
    # on the pixels such as scaling and cropping and writes the result to DRAM. It also collects
    # statistics to be used by control algorithms in the firmware i.e. Auto Exposure/Gain Control,
    # Auto White Balance and Auto Focus.
    #
    # The soft-realtime back end reads images from DRAM, splitting them into tiles.
    libcamera-vid -t 0 --inline -n --width 1280 --height 720 --framerate 30 --codec h264 --libav-format mpegts -o - \
        | ffmpeg -i - -c:v copy -f hls -hls_time 2 -hls_list_size 5 -hls_flags delete_segments -hls_allow_cache 0 /usr/html/stream_%v.m3u8
}

echo "initializing pider"

mount -t debugfs none /sys/kernel/debug

setup_firewall

setup_network

setup_ssh_server

setup_https_server

setup_livestream &