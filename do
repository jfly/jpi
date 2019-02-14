#!/usr/bin/env bash

set -e

function help() {
    echo "This script will help you set up a hidproxy device.
Currently it only works with the Raspberry Pi Zero W.

Some useful commands:
  $0 sdcard - to initialize an sd card.
  $0 bootstrap - to initialize device running with a fresh scdard."
}

function sdcard() {
    sdcard_path=$1
    echo "TODO <<< >>>"
    exit 1 # TODO >>> <<<

    # Instructions from <https://www.raspberrypi.org/documentation/installation/installing-images/linux.md>.
    wget https://downloads.raspberrypi.org/raspbian_lite_latest
    unzip -p raspbian_lite_latest | sudo dd bs=4M of=/dev/sdX status=progress conv=fsync

    # Headless setup (https://www.raspberrypi.org/forums/viewtopic.php?t=191252)
    sudo mount sdcard_path /mnt
    sudo touch /mnt/ssh
    echo "country=us
update_config=1
ctrl_interface=/var/run/wpa_supplicant

network={
 scan_ssid=1
 ssid=\"dagron\"
 psk=\"boobik's rube\"
}" | sudo tee /mnt/wpa_supplicant.conf
    $ sudo umount /mnt
    echo 
}

function bootstrap() {
    # TODO - rename the device to maybe hidproxy.local?
    ssh_url=pi@raspberrypi

    #<<< echo "First, let's change the password on the device."
    #<<< ssh -t $ssh_url passwd # TODO - maybe remove password instead?
    #<<<
    #<<< echo "Second, let's update the device."
    #<<< ssh $ssh_url "sudo apt-get update && sudo apt-get full-upgrade"

    echo "Third, let's copy all our code to the device."
    rsync -chavzP --rsync-path="sudo rsync" for-rpi/ $ssh_url:/

    echo "Fourth, let's set up all the code for running hidproxy."
    ssh $ssh_url hidproxy-bootstrap
}

sub_command=${1-help}; shift
$sub_command
