#!/bin/sh

# Set billy_pi_defconfig as the buildroot config.
BR2_DEFCONFIG=$(realpath billy_pi/billy_pi_defconfig) make -C buildroot defconfig

# Build the image.
make -j$(nproc) -C buildroot all
