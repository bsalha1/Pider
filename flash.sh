#!/bin/sh

sudo dd if=buildroot/output/images/sdcard.img of=/dev/mmcblk0 bs=4M conv=fsync status=progress