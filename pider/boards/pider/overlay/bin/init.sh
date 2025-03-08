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
    # Mount pseudo terminal filesystem - rw by root, w by tty group, inaccessible for anyone else.
    mkdir /dev/pts
    mount -t devpts devpts /dev/pts -o gid=5,mode=620

    # Generate some host keys.
    ssh-keygen -A

    # Start SSH server.
    /usr/sbin/sshd
}

setup_https_server()
{
    # Set up FastCGI for commands to the backend. Keep socket up to date with /etc/nginx.conf.
    mkdir -p /var/run
    fcgiwrap -s unix:/var/run/fcgiwrap.socket &

    # Allow nginx worker processes to access the socket.
    until [ -e /var/run/fcgiwrap.socket ]; do
        usleep 100000
    done
    chown www-data /var/run/fcgiwrap.socket

    # Start HTTPS server.
    mkdir -p /var/log/nginx
    mkdir -p /var/cache/nginx
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
    libcamera-vid -t 0 --inline -n --width 1920 --height 1080 --bitrate 12000000 --framerate 60 --codec h264 --libav-format mpegts -o - \
        | ffmpeg -i - -r 60 -c:v copy -f hls -hls_time 1 -hls_list_size 1 -hls_flags independent_segments+delete_segments -hls_allow_cache 0 /usr/html/stream_%v.m3u8

}

setup_firewall

setup_network

setup_ssh_server

setup_https_server

setup_livestream &