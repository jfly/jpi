#!/bin/sh

set -u
set -e
cd "$(dirname "$0")"

# Copy over the ssh keys of whoever is building this project.
# This clever idea was stolen from http://lists.busybox.net/pipermail/buildroot/2013-April/071111.html
mkdir -p "${TARGET_DIR}/root/.ssh/"
chmod 0700 "${TARGET_DIR}/root/.ssh/"
chmod 0700 "${TARGET_DIR}/root"
cp -p ~/.ssh/id_rsa.pub "${TARGET_DIR}/root/.ssh/authorized_keys"
chmod 0600 "${TARGET_DIR}/root/.ssh/authorized_keys"

# Look up wifi information and update wpa_supplicant template file.
WIFI_SSID="Hen Wen"
WIFI_PASSWORD=$(nmcli --show-secrets -g 802-11-wireless-security.psk connection show "$WIFI_SSID")
sed -i "s/REPLACE_WITH_SSID/$WIFI_SSID/" "${TARGET_DIR}/etc/wpa_supplicant.conf"
sed -i "s/REPLACE_WITH_PSK/$WIFI_PASSWORD/" "${TARGET_DIR}/etc/wpa_supplicant.conf"

# Copy custom config.txt file with dtoverlay.
cp config.txt "${BINARIES_DIR}/rpi-firmware/config.txt"

# Replace the DHCP hostname with the correct, configured hostname.
HOSTNAME=$(grep -Po '(?<=BR2_TARGET_GENERIC_HOSTNAME=")[^"]+' "$BR2_CONFIG")
sed -i "s/REPLACE_WITH_HOSTNAME/$HOSTNAME/" "${TARGET_DIR}/etc/network/interfaces"
