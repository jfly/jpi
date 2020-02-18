Some code for a Raspberry Pi Zero W to make it act as a Bluetooth HID proxy.

TODO - disable keyboard on raspberry pi somehow? this seems like a good way to lock yourself out of the device...

>>> TODO <<< documentation and examples
- FnLk does not work on bt keyboard. probably because we're only proxying bt -> raspberry pi -> usb host and nothing the other direction
- middle mouse and drag is weird... seems to trigger a full middle click which is annoying on the web. no idea what to investigate there

```
$ ./do sdcard
# Now plug in the sd card and boot up the pi!
$ ssh-copy-id pi@raspberrypi
$ ./do bootstrap
```


## Record bt keyboard

```
$ sudo script -c btmon /dev/null | grep --line-buffered -Eo "a1 ([0-f][0-f] )+" | tee /tmp/bt-snoop.out
```

## Playback bt keyboard

```
$ sleep 1 && cat /tmp/bt-snoop.out | ssh pi@raspberrypi 'sudo ./keyboard.py'
```

## It works! (Kind of)

Trackpoint isn't working great, I haven't investigated why yet.

```
pi@raspberrypi:~ $ sudo script -c btmon /dev/null | grep --line-buffered -Eo "a1 ([0-f][0-f] )+" | sudo ./keyboard.py
```

## Hotswapping

```
# Removing function
root@raspberrypi:/sys/kernel/config/usb_gadget/isticktoit# rm configs/c.1/hid.usb0

# Adding function back
root@raspberrypi:/sys/kernel/config/usb_gadget/isticktoit# ln -s functions/hid.usb0/ configs/c.1/hid.usb0
root@raspberrypi:/sys/kernel/config/usb_gadget/isticktoit# ls /sys/class/udc > UDC

# When adding a new function, need to first disable the device (https://www.kernel.org/doc/Documentation/usb/gadget_configfs.txt)
$ echo "" > UDC
```


And the corresponding action over in udev:

```
pi@raspberrypi:~ $ udevadm monitor --subsystem-match=hidg
monitor will print the received events for:
UDEV - the event which udev sends out after rule processing
KERNEL - the kernel uevent
KERNEL[5321.781177] remove   /devices/virtual/hidg/hidg0 (hidg)
UDEV  [5321.809712] remove   /devices/virtual/hidg/hidg0 (hidg)
KERNEL[5337.379114] add      /devices/virtual/hidg/hidg0 (hidg)
UDEV  [5337.448136] add      /devices/virtual/hidg/hidg0 (hidg)

pi@raspberrypi:~ $ ls -alh /dev/char/$(cat /sys/devices/virtual/hidg/hidg0/dev)
lrwxrwxrwx 1 root root 8 Oct 17 17:19 /dev/char/243:0 -> ../hidg0
```

## Misc

`bluetootctl` would crash while pairing my M720 mouse until I followed the
instructions on <https://askubuntu.com/a/660918>:

```
$ hciconfig hci0 sspmode 1
$ hciconfig hci0 down
$ hciconfig hci0 up
```


```
$ udevadm monitor
```

Some info about given hidraw device:

```
/devices/pci0000:00/0000:00:14.0/usb1/1-7/1-7:1.0/bluetooth/hci0/hci0:3585
```

I think the `hidp` kernel module is what exposes bt hid devices as virtual hid
devices? Not sure how `uhid` fits into this... It *seems* like you should be
able to issue an ioctl to get information
about the connections (see
https://github.com/torvalds/linux/blob/master/net/bluetooth/hidp/core.c), but I
can't find anyone online doing that, and I'm too scared/lazy to craft my own query.

It also feels to me like we should be able to figure out the device type of
/dev/hidraw0, but I can't figure out how to. `sudo udevadm info -a -p $(sudo
udevadm info -q path -n /dev/hidraw0)` is not very useful.


Other places to look:

- `/sys/class/hidraw`
- `/proc/bus/input/devices`
- `/sys/kernel/debug/hid/`

- `sudo cat /sys/class/hidraw/hidraw0/device/report_descriptor | xxd`
- `ls -alh /dev/char/$(cat /sys/class/hidraw/hidraw0/dev)`





===========================

$ udevadm monitor --udev --subsystem-match=hidraw

# Mouse events
UDEV  [1336.175307] add      /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:64 (bluetooth)
UDEV  [1348.641949] remove   /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:64 (bluetooth)

# Some of the many keyboard events
UDEV  [1438.468599] add      /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:12 (bluetooth)
UDEV  [1438.607243] add      /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:12/0005:17EF:6048.0005 (hid)
UDEV  [1438.663817] add      /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:12/0005:17EF:6048.0005/hidraw/hidraw0 (hidraw)
...
UDEV  [1515.948465] remove   /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:12/0005:17EF:6048.0005/hidraw/hidraw0 (hidraw)
UDEV  [1515.952424] remove   /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:12/0005:17EF:6048.0005/input/input4 (input)
UDEV  [1515.957221] remove   /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:12/0005:17EF:6048.0005 (hid)
UDEV  [1516.061966] remove   /devices/platform/soc/20201000.serial/tty/ttyAMA0/hci0/hci0:12 (bluetooth)


$ udevadm monitor --subsystem-match=hid

#######

/etc/udev/rules.d/90-my.rules
/etc/systemd/system/hidproxy@.service
/bin/hidproxy

$ sudo udevadm control --reload
$ sudo systemctl daemon-reload
$ systemctl status 'hidproxy*'


## Setting up ECM network (rndirs modem?)

Following instructions on http://irq5.io/2016/12/22/raspberry-pi-zero-as-multiple-usb-gadgets/:

```
$ cd /sys/kernel/config/usb_gadget/isticktoit
root@raspberrypi:/sys/kernel/config/usb_gadget/isticktoit# mkdir -p functions/rndis.usb3
root@raspberrypi:/sys/kernel/config/usb_gadget/isticktoit# ln -s functions/rndis.usb3 configs/c.1/
/root@raspberrypi:/sys/kernel/config/usb_gadget/isticktoit# echo > UDC
root@raspberrypi:/sys/kernel/config/usb_gadget/isticktoit# ls /sys/class/udc/ > UDC
```

## Setting up Buildroot

https://github.com/buildroot/buildroot/tree/master/board/raspberrypi

### TODO

- Figure out how to build rust code + run code on boot
   - this looks like promising instructions: http://www.elebihan.com/posts/how-to-add-a-buildroot-package-for-a-cargo-crate.html
- Raspberry PI gpio? one-wire protocol?
- Figure out a better way of naming devices. Should we ask the user for a
   name? Should we autogenerate one and print it out clearly?
   - For now: need to update `BR2_TARGET_GENERIC_HOSTNAME` in `out/.config` and
   - `buildroot-external/thermometer/overlay/etc/network/interfaces`
- Set up a read-only rootfs?
- Maybe add a non-root user + sudo? Then we could remove the custom sshd configuration.
- OTA updates (swupdate looks like a tool some people use)
