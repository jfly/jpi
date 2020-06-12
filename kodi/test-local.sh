#!/usr/bin/env bash

# Clobbers the ~/.kodi directory on the host computer and configures it for a
# "fresh" setup. This is a decent approximation of setting up a fresh sdcard,
# and a lot less work.

set -e

loopback_device=$(sudo losetup -P -f --show out/LibreELEC-jpi.img)
sudo mkdir -p out/mnt
sudo mount "${loopback_device}p1" out/mnt
sudo mkdir -p out/storage
sudo mount "${loopback_device}p2" out/storage
function finish {
    sudo umount out/storage
    sudo umount out/mnt
    sudo losetup -d "$loopback_device"
}
trap finish EXIT

# Now actually copy over the host's .kodi directory.
rm -rf ~/.kodi
mkdir ~/.kodi
sudo rsync -r out/storage/.kodi/ ~/.kodi
sudo chown -R "$USER:$USER" ~/.kodi
