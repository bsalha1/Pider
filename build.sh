#!/bin/sh

# NOTE: This script is only supported when executed in the docker container via build_docker.sh.

# Set pider_defconfig as the buildroot config.
BR2_EXTERNAL=$(realpath pider) make -C buildroot pider_defconfig
make -j$(nproc) -C buildroot all