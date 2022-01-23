# jpi

Configurations (many buildroot based) for miscellaneous Raspberry Pi projects
of mine:

- [hidproxy](#hidproxy)
- [thermometer](#thermometer)
- [thermostat](#thermostat)
- [garage](#garage)


## basic-raspbian

All Raspberry Pi models

    BOARD=basic-raspbian make sdcard

A basic raspbian lite image set up to connect to the snowdon wifi with ssh
enabled with the current user's keys added. To connect:

    ssh pi@raspberrypi

## basic-arch-rpi*

Rasperry Pi 4

    BOARD=basic-arch-rpi4 make sdcard

Raspberry Pi 3b+

    BOARD=basic-arch-rpi3b+ make sdcard

A basic arch arm image. To connect:

    ssh root@alarmpi

Once connected, initialize the pacman keyring and populate the Arch Linux ARM
package signing keys (step 10 of
https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4):

    pacman-key --init
    pacman-key --populate archlinuxarm

Note: After connecting, consider installing `sudo` and disabling root access in favor
of using the `alarm` user.

    pacman -Syuu
    pacman -S sudo
    visudo  # uncomment relevant line near the bottom, depending on what kind of sudo you want
    vi /etc/ssh/sshd_config  # change 'PermitRootLogin without-password' (near the bottom) to 'PermitRootLogin no'
    systemctl restart sshd  # to load the updated sshd configuration (or consider rebooting if the previous step installed a kernel update)

## hidproxy

Raspberry Pi Zero W

    BOARD=hidproxy make sdcard

WIP WIP WIP
Connects via bluetooth to HID devices, and exposes itself as a USB HID device.
This is useful when dual-booting, or if you want to set up a hub that any
computer can plug into and have devices just work.

Relvant discussions:

  - https://www.0xf8.org/2014/02/the-crux-of-finding-a-hid-proxy-capable-usb-bluetooth-adapter/
  - http://times.usefulinc.com/2004/06/12-hidproxy
  - https://www.tonymacx86.com/threads/bluetooth-usb-adapter-with-hid-proxy-mode.109961/
  - https://github.com/mikerr/pihidproxy

## thermometer

Raspberry Pi Zero W

    BOARD=thermometer make sdcard

Presents a HTTP api for a connected 1-wire thermometer (such as the DS18B20 or the MAX31820).
See [this Google Doc][thermostat doc] for more information

## thermostat

Raspberry Pi Zero W

    BOARD=thermostat make sdcard

Presents a HTTP api to control a furnace (by driving two attached relays).
See [this Google Doc][thermostat doc] for more information

[thermostat doc]: https://docs.google.com/document/d/19nYJWsHrPTapQddteFwLnRkTK_-vMuOusMupaPRWAcI/

## garage

Raspberry Pi Zero W

    BOARD=garage make sdcard

Presents a HTTP api to check and change the status of the garage door.

Inspired by: https://www.hagensieker.com/wordpress/2019/01/29/making-your-garage-door-smart/
