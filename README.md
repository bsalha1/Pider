
# Pider

- [Pider](#pider)
  - [Overview](#overview)
  - [Boot](#boot)
  - [Security](#security)
  - [Build](#build)
  - [Deploy](#deploy)
  - [Access](#access)

## Overview
Pider is a build system to build a purely open source platform for the Raspberry Pi 5 including:
- ARM Trusted Firmware bootloader
- Linux kernel
- Root filesystem

It is a minimalistic platform based on buildroot which contains a plethora of open source tools and libraries. We only build what is useful to do basic tasks on the device.

The ultimate goal of this task is to host an HTTPS server on the device which streams surveillance footage from an IMX708 image sensor. This is so I can make sure my dog Juniper doesn't die while I'm gone. Maybe I will add some post-processing to detect movement or other useful phenomena.

## Boot
After Linux is finished booting, BusyBox init is invoked which executes processes per [inittab](pider/boards/pider/overlay/etc/inittab). This mounts the typically-useful filesystems and make some typically-used directories and ultimately invokes a shell script called [init.sh](pider/boards/pider/overlay/bin/init.sh). This script is used to do our specific configurations of the system and kick off all the processes that will run (unless a user tunnels in). Those consist of:
1. Mount kernel debugfs.
2. Set up firewall.
3. Get an IP address for the Wi-Fi and Ethernet interfaces from a discovered DHCP server.
4. Start SSH server.
5. Start HTTPS server.

## Security
The platform uses a [netfilter-based firewall](pider/boards/pider/overlay/etc/nftables.conf) which blocks all incoming traffic except if destined to the typicall SSH (22) and HTTPS (443) ports. It also does not allow forwarding.

## Build
This only builds in Linux-based environments.

1. Execute `git submodule update --init` to clone arm-trusted-firmware, buildroot and linux.
2. Execute `./build.sh` to build the platform.

This will produce some images and 1 Raspberry Pi bootable image:
- `bl31.bin`: ARM Trusted Firmware bootloader.
- `Image`: Linux kernel executable.
- `rootfs.cpio.gz`: Compressed root filesystem.
- Device tree overlays for various devices that can be connected to the Raspberry Pi.
- `sdcard.img`: Contains the above images along with two files read by the Raspberry Pi's firmware/bootloader:
  - [config.txt](pider/boards/pider/config.txt): configures the device tree parameters, overlays and other low level initialization.
  - [cmdline.txt](pider/boards/pider/cmdline.txt): configures the command-line arguments to execute the kernel with.

## Deploy
1. Plug an SD card into the computer used to build and execute `./flash.sh <block device name>` i.e. `./flash.sh /dev/mmcblk0` which flashes the SD card with the platform. Upon inserting the SD card into the Raspberry Pi and powering up the device, it should boot into the platform.

or

2. Execute `./deploy.sh root@<ip address> -r` to deploy the image to the Raspberry Pi (execute `ip addr` on the Raspberry Pi to find the IP address on either `eth0` or `wlan0`) where the script will then flash the SD card with the platform and reboot (omit `-r` argument to not reboot).

## Access
By default, the operating system can be accessed the following ways:

- **UART**: Username is `root`, password is `soup`.
- **SSH**: Password authentication is not supported due to its inherent security flaws. Instead, to access the device over SSH, add the public key of your machine to the [authorized_keys](pider/boards/pider/overlay/root/.ssh/authorized_keys) file and ssh in as `root`. You can generate a private-public key pair on your machine by executing `ssh-keygen`. Then paste the contents of the generated `.pub` file into the [authorized_keys](pider/boards/pider/overlay/root/.ssh/authorized_keys) file.

To connect to a Wi-Fi Access Point, add a file called `wpa_supplicant.conf` to the root filesystem overlay [etc](pider/boards/pider/overlay/etc). For security reasons, this file is not included in this repository and is in the `gitignore`. See [the man page](https://linux.die.net/man/5/wpa_supplicant.conf) to learn what to put into `wpa_supplicant.conf`.