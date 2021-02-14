#!/usr/bin/env bash

# Instructions modified from
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
# - https://sick.codes/how-to-install-arch-linux-on-raspberry-pi-4-and-3b-plus/

set -e

# Create a disk image with two partitions on it.
BOOT_PARTITION_MB=200
ROOT_PARTITION_MB=1536
dd if=/dev/zero of=out/archarm-jpi-wip.img bs=1M count=$((1 + BOOT_PARTITION_MB + ROOT_PARTITION_MB))
echo "label: dos
label-id: 0x72147d4e
device: out/archarm-jpi-wip.img
unit: sectors
sector-size: 512

out/archarm-jpi-wip.img1 : start=1MiB,                          size=${BOOT_PARTITION_MB}MiB, type=c, bootable
out/archarm-jpi-wip.img2 : start=$((1 + BOOT_PARTITION_MB))MiB, size=${ROOT_PARTITION_MB}MiB, type=83" | sfdisk out/archarm-jpi-wip.img

loopback_device=$(sudo losetup -P -f --show out/archarm-jpi-wip.img)
# Format the boot partition.
sudo mkfs.vfat "${loopback_device}p1"
# Format the root partition.
sudo mkfs.ext4 "${loopback_device}p2"

# Mount the freshly created partitions.
mkdir -p out/boot
sudo mount "${loopback_device}p1" out/boot
mkdir -p out/root
sudo mount "${loopback_device}p2" out/root
function finish {
    sudo umount out/boot
    sudo umount out/root
    sudo losetup -d "$loopback_device"
}
trap finish EXIT

# Extracting using `sudo` is necessary to avoid this errors:
#  ./usr/bin/newuidmap: Cannot restore extended attributes: security.capability security.capability
#  ./usr/bin/ping: Cannot restore extended attributes: security.capability security.capability
#  ./usr/bin/newgidmap: Cannot restore extended attributes: security.capability security.capability
sudo bsdtar -xpf "${SOURCE_TARZIP}" -C out/root
sudo mv out/root/boot/* out/boot/

# Copy over the ssh keys of whoever is building this project.
# This clever idea was stolen from http://lists.busybox.net/pipermail/buildroot/2013-April/071111.html
HOME_DIR=out/root/root
sudo mkdir -p "${HOME_DIR}/.ssh/"
sudo chmod 0700 "${HOME_DIR}/.ssh/"
sudo chmod 0700 "${HOME_DIR}/"
sudo cp -p ~/.ssh/id_rsa.pub "${HOME_DIR}/.ssh/authorized_keys"
sudo chown root:root "${HOME_DIR}/.ssh/authorized_keys"
sudo chmod 0600 "${HOME_DIR}/.ssh/authorized_keys"
HOME_DIR=out/root/home/alarm
mkdir -p "${HOME_DIR}/.ssh/"
chmod 0700 "${HOME_DIR}/.ssh/"
chmod 0700 "${HOME_DIR}/"
cp -p ~/.ssh/id_rsa.pub "${HOME_DIR}/.ssh/authorized_keys"
chmod 0600 "${HOME_DIR}/.ssh/authorized_keys"

# Remove the root and alarm users's passwords entirely.
sudo sed -i 's/^root:[^:]*:\(.*\)/root::\1/' out/root/etc/shadow
sudo sed -i 's/^alarm:[^:]*:\(.*\)/alarm::\1/' out/root/etc/shadow

# Enable root ssh. It would be better to not do this and only allow ssh-ing as
# the alarm user, but sudo isn't set up, so there's no way to do anything
# terribly useful as the alarm user. I tried downloading
# https://archlinuxarm.org/packages/armv7h/sudo and extracting it to the root
# of the filesystem, but it didn't actually work (when I booted up and tried to
# use it, it complained about needing a different version of glibc than was
# actually installed).
sudo bash -c 'echo "PermitRootLogin without-password" >> out/root/etc/ssh/sshd_config'
# Disable password based ssh authentication.
sudo bash -c 'echo "PasswordAuthentication no" >> out/root/etc/ssh/sshd_config'

# Set up the hostname
HOSTNAME="alarmpi"
echo "$HOSTNAME" | sudo tee out/root/etc/hostname

# Set up wifi credentials.
WIFI_SSID="Hen Wen"
WIFI_PASSWORD=$(nmcli --show-secrets -g 802-11-wireless-security.psk connection show "$WIFI_SSID")
echo "Description='Connect to snowdon wifi'
Interface=wlan0
Connection=wireless

Security=wpa
IP=dhcp

ESSID='$WIFI_SSID'
Key='$WIFI_PASSWORD'
# This undocumented netctl setting allows passing additional parameters to
# dhcpcd. The -L comes from the default options, and I've added in the
# --hostname. See http://www.sigexec.com/posts/netctl-undocumented-features/
# for some details.
DhcpcdOptions='-L --hostname'
" | sudo tee out/root/etc/netctl/wlan0-snowdon
# Connect to wifi on boot.
# This was created by following the output of `netctl enable wlan0-snowdon` on
# a real machine.
sudo mkdir -p out/root/etc/systemd/system/netctl\@wlan0\\x2dsnowdon.service.d/
echo "[Unit]
Description=Connect to snowdon wifi
BindsTo=sys-subsystem-net-devices-wlan0.device
After=sys-subsystem-net-devices-wlan0.device
" | sudo tee out/root/etc/systemd/system/netctl\@wlan0\\x2dsnowdon.service.d/profile.conf
echo "[Unit]
Description=Networking for netctl profile %I
Documentation=man:netctl.profile(5)
After=network-pre.target
Before=network.target netctl.service
Wants=network.target

[Service]
Type=notify
NotifyAccess=exec
RemainAfterExit=yes
ExecStart=/usr/lib/netctl/network start %I
ExecStop=/usr/lib/netctl/network stop %I
" | sudo tee out/root/usr/lib/systemd/system/netctl@.service
(
    cd out/root/etc/systemd/system/multi-user.target.wants/;
    sudo ln -s ../../../../usr/lib/systemd/system/netctl\@.service 'netctl@wlan0\x2dsnowdon.service';
)

# From https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4#aarch64installation
#
#  > Before unmounting the partitions, update /etc/fstab for the different SD
#  > block device compared to the Raspberry Pi 3:
#
# I guess that means the image we're using is actually for a Raspberry Pi 3?
sudo sed -i 's/mmcblk0/mmcblk1/g' out/root/etc/fstab

# Rename image to indicate that it's done!
mv out/archarm-jpi-wip.img out/archarm-jpi.img
