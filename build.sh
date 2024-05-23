#!/bin/sh

# Set billy_pi_defconfig as the buildroot config.
BR2_EXTERNAL=$(realpath billy_pi) make -C buildroot billy_pi_defconfig

# Build the image.
make -j$(nproc) -C buildroot all
