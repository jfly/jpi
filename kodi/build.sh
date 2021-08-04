#!/usr/bin/env bash

# Mount and extract a LibreELEC sdcard image and overlay some customizations.
# Basic idea cribbed from https://pvagner.tk/2016/how-to-hack-kodi-screen-reader-addon-into-libreelec-image

set -e

cp "${SOURCE_IMAGE}" out/LibreELEC-jpi-wip.img
loopback_device=$(sudo losetup -P -f --show out/LibreELEC-jpi-wip.img)
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


### Extract the squashfs.
sudo rm -rf out/squashfs-root out/SYSTEM out/SYSTEM.md5
sudo unsquashfs -d out/squashfs-root out/mnt/SYSTEM

### Make some tweaks to the filesystem.
# Load secrets into variables.
source <(scp clark:/mnt/media/.build-secrets/jpi-kodi.secrets /dev/stdout)
# Enable SSH (add "ssh" to the end of the line)
sudo gawk -i inplace '{print $0" ssh"}' out/mnt/cmdline.txt
# Enable aplay audio devices (kodi doesn't seem to need this, but parsec does)
# See https://github.com/bite-your-idols/Gamestarter/issues/39 for more information.
sudo bash -c 'echo "dtparam=audio=on" >> out/mnt/config.txt'
sudo rsync -r --links overlay/root/ out/squashfs-root
# Needed to get Pulseaudio to recognize our various output devices.
# Sort of from https://wiki.libreelec.tv/configuration/pulseaudio?
sudo bash -c 'echo "load-module module-udev-detect" >> out/squashfs-root/etc/pulse/system.pa'
# Copy files onto the /storage (aka "home") directory (it's a completely
# separate partition).
sudo rsync -r --links overlay/storage/ out/storage
# Copy the bluetooth configuration. (This isn't committed to git because it
# contains secret link keys.)
rsync -r clark:/mnt/media/.build-secrets/jpi-kodi-bluetooth /tmp/
sudo mv /tmp/jpi-kodi-bluetooth out/storage/.cache/bluetooth
# "Install" parsec
(
    rm -rf out/parsecing
    mkdir -p out/parsecing
    cd out/parsecing
    wget https://s3.amazonaws.com/parsec-build/package/parsec-rpi.deb
    ar xv parsec-rpi.deb
    sudo tar xf data.tar.xz -C ../squashfs-root
)
## Install/configure some kodi plugins.
## If you add a new plugin, don't forget to add it to the list of addons to
## enable in overlay/storage/.kodi/userdata/autoexec.py!
function add_plugin() {
    wget -O out/addon.zip "$1"
    sudo unzip out/addon.zip -d out/storage/.kodi/addons
}
# Opensubtitles.org
add_plugin "https://github.com/opensubtitles/service.subtitles.opensubtitles_by_opensubtitles/archive/master.zip"
# TubeCast
# (installation is in autoexec.py, because there are a bunch of dependencies
# that make installing by extracting a zip not a good option =()
sudo sed -i "s/{{ YOUTUBE_API_KEY }}/${YOUTUBE_API_KEY}/g" out/storage/.kodi/userdata/addon_data/plugin.video.youtube/api_keys.json
sudo sed -i "s/{{ YOUTUBE_CLIENT_ID }}/${YOUTUBE_CLIENT_ID}/g" out/storage/.kodi/userdata/addon_data/plugin.video.youtube/api_keys.json
sudo sed -i "s/{{ YOUTUBE_CLIENT_SECRET }}/${YOUTUBE_CLIENT_SECRET}/g" out/storage/.kodi/userdata/addon_data/plugin.video.youtube/api_keys.json

# Do some janky templating to handle secrets.
sudo sed -i "s/{{ MYSQL_USERNAME }}/${MYSQL_USERNAME}/g" out/storage/.kodi/userdata/advancedsettings.xml
sudo sed -i "s/{{ MYSQL_PASSWORD }}/${MYSQL_PASSWORD}/g" out/storage/.kodi/userdata/advancedsettings.xml
echo "$PARSEC_USER_BIN_BASE64" | base64 --decode | sudo tee out/storage/.parsec/user.bin
# Copy over the ssh keys of whoever is building this project.
# This clever idea was stolen from http://lists.busybox.net/pipermail/buildroot/2013-April/071111.html
HOME_DIR=out/storage
sudo mkdir -p "${HOME_DIR}/.ssh/"
sudo chmod 0700 "${HOME_DIR}/.ssh/"
sudo chmod 0700 "${HOME_DIR}/"
sudo cp -p ~/.ssh/id_rsa.pub "${HOME_DIR}/.ssh/authorized_keys"
sudo chmod 0600 "${HOME_DIR}/.ssh/authorized_keys"

### Done! Put everything back together again.
# Rebuild squashfs
sudo mksquashfs out/squashfs-root out/SYSTEM -b 524288 -comp lzo -no-xattrs
md5sum out/SYSTEM > out/SYSTEM.md5
# Copy squashfs back to img.
sudo cp out/SYSTEM out/mnt/SYSTEM
sudo cp out/SYSTEM.md5 out/mnt/SYSTEM.md5
# Rename image to indicate that it's done!
mv out/LibreELEC-jpi-wip.img out/LibreELEC-jpi.img
