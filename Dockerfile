# Many packages cannot be built with newer GCC versions, so we create a docker container on a
# debian distribution where all the packages can be built on.

# Base off of Debian Bookworm release which uses GCC 12.
FROM debian:bookworm

# Install dependencies.
RUN apt update && apt install -y \
    make \
    gcc \
    file \
    g++ \
    wget \
    cpio \
    unzip \
    rsync \
    bc \
    bzip2 \
    git \
    ncurses-dev \
    sudo

# Create builder user since building with root is disallowed for many packages.
RUN useradd -m builder
RUN usermod -aG sudo builder
RUN echo "builder ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder

CMD echo "Welcome to the build docker container, execute ./build.sh to build the platform." && exec bash

WORKDIR /mnt/host