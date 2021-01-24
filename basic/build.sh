#!/usr/bin/env bash

# Mount and extract a Raspbian sdcard image and overlay some customizations.
# Basic idea cribbed from:
#  - https://pvagner.tk/2016/how-to-hack-kodi-screen-reader-addon-into-libreelec-image
#  - https://www.tomshardware.com/reviews/raspberry-pi-headless-setup-how-to,6028.html

set -e

cp "${SOURCE_IMAGE}" out/raspbian-jpi-wip.img

loopback_device=$(sudo losetup -P -f --show out/raspbian-jpi-wip.img)
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

### Enable SSH
sudo touch out/mnt/ssh
# Copy over the ssh keys of whoever is building this project.
# This clever idea was stolen from http://lists.busybox.net/pipermail/buildroot/2013-April/071111.html
HOME_DIR=out/storage/home/pi
mkdir -p "${HOME_DIR}/.ssh/"
chmod 0700 "${HOME_DIR}/.ssh/"
chmod 0700 "${HOME_DIR}/"
cp -p ~/.ssh/id_rsa.pub "${HOME_DIR}/.ssh/authorized_keys"
chmod 0600 "${HOME_DIR}/.ssh/authorized_keys"
# Disable password based ssh authentication.
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' out/storage/etc/ssh/sshd_config

# Remove the pi user's password entirely.
sudo sed -i 's/^pi:[^:]*:\(.*\)/pi::\1/' out/storage/etc/shadow

# Set up credentials to connect to wifi.
WIFI_SSID="Hen Wen"
WIFI_PASSWORD=$(nmcli --show-secrets -g 802-11-wireless-security.psk connection show "$WIFI_SSID")
sudo tee out/mnt/wpa_supplicant.conf << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    scan_ssid=1
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
}
EOF

# Rename image to indicate that it's done!
mv out/raspbian-jpi-wip.img out/raspbian-jpi.img
