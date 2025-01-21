#!/bin/sh

# Set pider_defconfig as the buildroot config.
BR2_EXTERNAL=$(realpath pider) make -C buildroot pider_defconfig

# Build the image.
make -j$(nproc) -C buildroot all
