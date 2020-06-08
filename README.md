# jpi

Buildroot configurations for miscellaneous Raspberry Pi projects of mine:

- [hidproxy](#hidproxy)
- [thermometer](#thermometer)
- [thermostat](#thermostat)
- [garage](#garage)
- [kodi](#kodi)

To build a specific project (aka "board"):

    BOARD=thermostat make build

## hidproxy

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

Presents a HTTP api for a connected 1-wire thermometer (such as the DS18B20 or the MAX31820).
See [this Google Doc][thermostat doc] for more information

## thermostat

Raspberry Pi Zero W

Presents a HTTP api to control a furnace (by driving two attached relays).
See [this Google Doc][thermostat doc] for more information

[thermostat doc]: https://docs.google.com/document/d/19nYJWsHrPTapQddteFwLnRkTK_-vMuOusMupaPRWAcI/

## garage

Raspberry Pi Zero W

Presents a HTTP api to check and change the status of the garage door.

Inspired by: https://www.hagensieker.com/wordpress/2019/01/29/making-your-garage-door-smart/

## kodi

Raspberry PI 3B+
