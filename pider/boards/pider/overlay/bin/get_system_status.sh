#!/bin/sh
printf "Content-Type: text/html

$(cat /sys/class/thermal/thermal_zone0/temp)
$(cat /proc/uptime | awk -F" " '{ print $1 }')"