#!/bin/sh

# Build the docker container.
docker build -t build-container .

# Run the build container.
docker run -it -v .:/mnt/host build-container:latest
