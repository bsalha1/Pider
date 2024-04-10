#!/bin/sh

ssh -t 192.168.0.117 'sudo dd if=~/sdcard.img of=/dev/mmcblk0 bs=4M conv=fsync status=progress'