#!/bin/sh

# Override the linux source to point to our local copy of linux.
echo "LINUX_OVERRIDE_SRCDIR=\$(TOPDIR)/../linux-rpi" > buildroot/local.mk

# Set billy_pi_defconfig as the buildroot config.
BR2_DEFCONFIG=$(realpath billy_pi/billy_pi_defconfig) make -C buildroot defconfig

# Build the image.
make -j$(nproc) -C buildroot all