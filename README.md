
```
# Instructions from <https://www.raspberrypi.org/documentation/installation/installing-images/linux.md>.
$ wget https://downloads.raspberrypi.org/raspbian_lite_latest -o raspbian_lite_latest.zip
$ unzip -p raspbian_lite_latest.zip | sudo dd bs=4M of=/dev/sdX status=progress conv=fsync

# Headless setup (https://www.raspberrypi.org/forums/viewtopic.php?t=191252)
$ sudo mount /dev/sda1 /mnt
$ sudo touch /mnt/ssh
$ echo "country=us
update_config=1
ctrl_interface=/var/run/wpa_supplicant

network={
 scan_ssid=1
 ssid=\"dagron\"
 psk=\"boobik's rube\"
}" | sudo tee /mnt/wpa_supplicant.conf
$ sudo umount /mnt

# Now boot up the pi!
$ ssh-copy-id pi@raspberrypi
$ ssh pi@raspberrypi "sudo apt-get update && sudo apt-get upgrade"
$ ssh pi@raspberrypi passwd # TODO - maybe remove password instead?
$ scp bootstrap-pi.sh pi@raspberrypi:/tmp && ssh pi@raspberrypi /tmp/bootstrap-pi.sh
```
