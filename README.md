
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
After Linux is finished booting, [pider-init](pider/package/pider-init/src/init.cc) is invoked. The goal of pider-init is to do the bare minimum initialization and to execute the initialization script. This involves mounting procfs and sysfs, setting the hostname, starting the system logger, putting a login on the UART port and then finally executing the [init.sh](pider/boards/pider/overlay/bin/init.sh) script.

This script sets up the firewall which only lets in TCP packets destined to ports 22 (SSH), 80 (HTTP) and 443 (HTTPS) - this is configured in [nftables.conf](pider/boards/pider/overlay/etc/nftables.conf).

## Security
The platform uses a [netfilter-based firewall](pider/boards/pider/overlay/etc/nftables.conf) which blocks all incoming traffic except if destined to the typical SSH (22) and HTTPS (443) ports. It also does not allow forwarding.

## Build
This only builds in Linux-based environments.

1. Execute `git submodule update --init` to clone arm-trusted-firmware, buildroot and linux.
2. Execute `./build_docker.sh` to build the docker container used for building.
3. Execute `./build.sh` inside the docker container to build the platform.

This will produce some images and 1 Raspberry Pi bootable image:
- `bl31.bin`: ARM Trusted Firmware bootloader.
- `Image`: Linux kernel executable.
- `rootfs.cpio.gz`: Compressed root filesystem.
- Device tree overlays for various devices that can be connected to the Raspberry Pi.
- `sdcard.img`: Contains the above images along with two files read by the Raspberry Pi's firmware/bootloader:
  - [config.txt](pider/boards/pider/config.txt): configures the device tree parameters, overlays and other low level initialization.
  - [cmdline.txt](piderp/boards/pider/cmdline.txt): configures the command-line arguments to execute the kernel with.

## Deploy
1. Plug an SD card into the computer used to build and execute `./flash.sh <block device name>` i.e. `./flash.sh /dev/mmcblk0` which flashes the SD card with the platform. Upon inserting the SD card into the device and powering it up, it should boot into the platform. If your device has not run this platform before, this must be the method of deploying. Otherwise, approach (2) below is the preferred method for quicker iteration.

or

2. Execute `./deploy.sh <ip address> -r` to deploy the image to the device (See [Access](#access) for IP address information or, over serial, execute `ip addr` to get the IP address on `eth0` and `wlan0`) where the script will then flash the SD card with the platform and reboot (omit `-r` argument to not reboot).

## Access
By default, the operating system can be accessed the following ways:

- **UART**: Username is `root`, password is `soup`.
- **SSH**: Password authentication is not supported due to its inherent security flaws. Instead, to access the device over SSH, add the public key of your host machine to the [authorized_keys](pider/boards/pider/overlay/root/.ssh/authorized_keys) file and ssh in as `root`. You can generate a private-public key pair on your machine by executing `ssh-keygen` and then paste the contents of the generated `.pub` file into the [authorized_keys](pider/boards/pider/overlay/root/.ssh/authorized_keys) file.
  - **Wi-Fi**: To connect to a Wi-Fi Access Point, add a file called `wpa_supplicant.conf` to the root filesystem overlay [etc](pider/boards/pider/overlay/etc). For security reasons, this file is not included in this repository and is in the `.gitignore`. See [the man page](https://linux.die.net/man/5/wpa_supplicant.conf) to learn what to put into `wpa_supplicant.conf`.
  - **IP Address (and Ethernet)**: The device starts off assuming it is on a LAN and asks for an IP address over DHCP. If no DHCP server responds (like if the device is directly connected to another computer over Ethernet), the device configures a static IP address of `172.1.1.2/24` on its Ethernet interface. To be able to communicate with the device, one must execute the following on the connected computer: `ip addr add 172.1.1.<not 2>/24 dev <interface>`.
    - **DHCP-less Internet**: If it is desired to give the device access to a LAN connected to another port on the computer, which can potentially have a router on it with access to the Internet, we must set the IP address of the computer on its device-facing port to `172.1.1.1`. This IP address is special because the device has a default route via `172.1.1.1`, so if the device wanted to access `8.8.8.8` which is on the Internet, it will go to `172.1.1.1` which has a default route to a gateway `192.168.50.1` which forwards the packet to the ISP network to get to `8.8.8.8`. To support this on the host computer, do the following:
    ```
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A POSTROUTING -o <lan-facing-interface> -j MASQUERADE
    iptables -A FORWARD -i <device-facing-interface> -o <lan-facing-interface> -j ACCEPT
    iptables -A FORWARD -i <lan-facing-interface> -o <device-facing-interface> -m state --state RELATED,ESTABLISHED -j ACCEPT
    ip addr add 172.1.1.1/24 dev <device-facing-interface>
    ```