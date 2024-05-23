#!/bin/sh

sudo dd if=buildroot/output/images/sdcard.img of=/dev/sda bs=4M conv=fsync status=progress