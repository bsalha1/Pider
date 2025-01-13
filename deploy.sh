#!/bin/bash

set -e

RED='\033[0;31m'
LIGHT_BLUE='\033[1;34'm
NC='\033[0m'

usage()
{
    echo "usage: $0 [-r]
    -r: reboot after updating the SD card."
}

# Parse arguments, if any.
reboot=false
if [ $# -gt 0 ]; then
    if [ "$1" = "-r" ]; then
        reboot=true
    else
        usage
        exit 1
    fi
fi

echo -e "${LIGHT_BLUE}Copying image to rpi${NC}..."
scp buildroot/output/images/sdcard.img root@bilal-rpi:/tmp

cmd=
if $reboot; then
    cmd="dd if=/tmp/sdcard.img of=/dev/mmcblk0 bs=4M conv=fsync && reboot"
else
    cmd="dd if=/tmp/sdcard.img of=/dev/mmcblk0 bs=4M conv=fsync"
fi

echo -e "${LIGHT_BLUE}Writing image to rpi${NC}..."
ssh root@bilal-rpi -t "$cmd"
