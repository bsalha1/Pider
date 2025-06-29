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

    has_wireless_interface=false

    # If the wpa_supplicant config exists, connected to the Wi-Fi access point.
    if [ -e /etc/wpa_supplicant.conf ]
    then
        has_wireless_interface=true

        # The brcmfmac module (Wi-Fi MAC) takes some time to initialize. Let's wait for the
        # interface to show up.
        while ! grep -q wlan0 /proc/net/dev
        do
            usleep 100000
        done

        wpa_supplicant -dd -B -D wext -i wlan0 -c /etc/wpa_supplicant.conf
    fi

    # Get IP address via DHCP over Ethernet.
    dhcp_worked=false
    if dhclient -1 -v -cf /etc/dhclient.conf eth0; then
        dhcp_worked=true
    else
        # If DHCP didn't work, we are probably directly connected to someone's computer. Let's
        # hope they know our static IP address. Let's assign it outside the subnet of most LANs.
        #
        # For the computer, do the following to communicate with us:
        # ip addr add 172.1.1.1/24 dev <interface>
        #
        ip addr flush dev eth0
        ip addr add 172.1.1.2/24 dev eth0
        ip link set eth0 up
    fi

    # Get IP address via DHCP over Wi-Fi. There's no fallback behavior.
    if $has_wireless_interface; then
        if dhclient -1 -v -cf /etc/dhclient.conf wlan0; then
            dhcp_worked=true
        fi
    fi

    # If DHCP didn't work for Ethernet or Wi-Fi, assume we are directly connected to a computer over
    # Ethernet.
    if ! $dhcp_worked; then
        # If the computer is connected to a LAN on another one of its ports and has forwarding
        # enabled, we can access the LAN by setting our default route to the computer. Here we
        # assume that the computer assigned the IP address of the network interface facing us to
        # 172.1.1.1.
        ip route add default via 172.1.1.1
    fi
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