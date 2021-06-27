#!/bin/bash

HOSTNAME="firecracker"
hostnamectl set-hostname $HOSTNAME

# Get firecracker
cd /root
release_url="https://github.com/firecracker-microvm/firecracker/releases"
latest=$(basename $(curl -fsSLI -o /dev/null -w  %{url_effective} ${release_url}/latest))
arch=`uname -m`
curl -L ${release_url}/download/${latest}/firecracker-${latest}-${arch}.tgz | tar -xz &>/dev/null &&
cd release-${latest} &&
mv firecracker-${latest}-$(uname -m) /usr/local/sbin/firecracker
