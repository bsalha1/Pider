#!/bin/bash

set -e

LIGHT_BLUE='\033[1;34'm
NC='\033[0m'

usage()
{
    echo "usage: $0 [rpi ip addr] [-r]
    -r: reboot after updating the SD card."
}

# Parse arguments, if any.
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

ip="$1"
reboot=false
if [ $# -gt 1 ]; then
    if [ "$2" = "-r" ]; then
        reboot=true
    else
        usage
        exit 1
    fi
fi

echo -e "${LIGHT_BLUE}Copying image to rpi${NC}..."
scp buildroot/output/images/sdcard.img "root@$ip:/tmp"

cmd=
if $reboot; then
    cmd="dd if=/tmp/sdcard.img of=/dev/mmcblk0 bs=4M conv=fsync && reboot -f"
else
    cmd="dd if=/tmp/sdcard.img of=/dev/mmcblk0 bs=4M conv=fsync"
fi

echo -e "${LIGHT_BLUE}Writing image to rpi${NC}..."
ssh "root@$ip" "$cmd"
