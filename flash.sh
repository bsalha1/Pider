#!/bin/sh

usage()
{
    echo "usage: $0 [block device i.e. /dev/mmcblk0]"
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

dev="$1"

sudo dd if=buildroot/output/images/sdcard.img "of=$dev" bs=4M conv=fsync status=progress