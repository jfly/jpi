#!/usr/bin/env bash

model=$(tr -d '\0' < /proc/device-tree/model)
if [ "$model" != "Raspberry Pi Zero W Rev 1.1" ]; then
    echo "Uh oh, I'm not sure how to handle your device: $model"
    exit 1
fi

function enable_kernel_modules() {
    # TODO - only do all of this one time.

    # Copied from https://randomnerdtutorials.com/raspberry-pi-zero-usb-keyboard-hid/
    echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
    echo "dwc2" | sudo tee -a /etc/modules
    sudo echo "libcomposite" | sudo tee -a /etc/modules
}

function create_etc_rc_local() {
    sudo tee /etc/rc.local > /dev/null <<'EOF'
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

if [ -d /etc/rc.local.d/ ]; then
    for f in /etc/rc.local.d/*.sh; do
        echo "*** Executing $f ***"
        $f
    done
fi

exit 0
EOF
}

function create_gadget_setup_script() {
    sudo mkdir -p /etc/rc.local.d/
    sudo tee /etc/rc.local.d/setup_gadget.sh > /dev/null <<'EOF'
#!/usr/bin/env bash

cd /sys/kernel/config/usb_gadget/
mkdir -p isticktoit
cd isticktoit
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Tobias Girstmair" > strings/0x409/manufacturer
echo "iSticktoit.net USB Device" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# Add functions here
# mkdir -p functions/hid.usb0
# echo 1 > functions/hid.usb0/subclass  # boot interface subclass
# echo 1 > functions/hid.usb0/protocol  # keyboard. according to https://www.usb.org/sites/default/files/documents/hid1_11.pdf, "The bInterfaceProtocol member of an Interface descriptor only has meaning if the bInterfaceSubClass member declares that the device supports a boot interface, otherwise it is 0"
# echo 8 > functions/hid.usb0/report_length  # ??? see https://github.com/torvalds/linux/blob/master/drivers/usb/gadget/function/f_hid.c
# Copied from /sys/kernel/debug/hid/0005:17EF:6048.009A/rdesc when bluetooth keyboard was connected to my laptop.
# echo "05 01 09 06 a1 01 85 01 75 01 95 08 05 07 19 e0 29 e7 15 00 25 01 81 02
81 01 75 01 95 05 05 08 19 01 29 05 91 02 95 03 91 01 75 08 95 06 26 ff 00 05
07 19 00 2a ff 00 81 00 c0 05 01 09 02 a1 01 85 02 09 01 a1 00 05 09 19 01 29
03 15 00 25 01 75 01 95 03 81 02 75 05 95 01 81 01 05 01 09 30 09 31 15 81 25
7f 75 08 95 02 81 06 09 38 15 81 25 7f 75 08 95 01 81 06 05 0c 0a 38 02 95 01
81 06 c0 c0 05 0c 09 01 a1 01 85 10 19 00 2a ff 03 75 0c 95 01 15 00 26 ff 03
81 00 75 04 95 01 81 01 c0 05 01 09 0c a1 01 85 11 19 00 2a ff 00 15 00 26 ff
00 75 08 95 01 81 00 c0 05 01 09 80 a1 01 85 12 15 00 25 01 75 01 95 03 09 81
09 82 09 83 81 02 95 01 75 05 81 03 c0 05 0c 09 01 a1 01 85 13 05 01 09 06 a1
02 05 06 09 20 15 00 26 ff 00 75 08 95 01 81 02 06 bc ff 0a ad bd 75 08 95 06
81 02 09 01 75 08 95 07 b1 02 c0 c0 06 00 ff 09 01 a1 01 85 15 1a f1 00 2a fc
00 15 00 25 01 75 01 95 0d 81 02 95 03 81 01 c0 06 10 ff 09 01 a1 01 85 16 19
00 2a ff 00 15 00 26 ff 00 75 08 95 02 81 00 c0 06 02 ff 09 01 a1 01 85 17 15
00 25 ff 19 00 29 ff 95 08 75 08 81 00 c0 06 01 ff 09 01 a1 01 85 18 15 00 25
ff 19 00 29 ff 95 08 75 08 91 00 c0 00" | xxd -r -p > functions/hid.usb0/report_desc
#echo -ne \\x05\\x01\\x09\\x06\\xa1\\x01\\x05\\x07\\x19\\xe0\\x29\\xe7\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02\\x95\\x01\\x75\\x08\\x81\\x03\\x95\\x05\\x75\\x01\\x05\\x08\\x19\\x01\\x29\\x05\\x91\\x02\\x95\\x01\\x75\\x03\\x91\\x03\\x95\\x06\\x75\\x08\\x15\\x00\\x25\\x65\\x05\\x07\\x19\\x00\\x29\\x65\\x81\\x00\\xc0 > functions/hid.usb0/report_desc
# ln -s functions/hid.usb0 configs/c.1/

# mkdir -p functions/hid.usb1
# echo 2 > functions/hid.usb1/protocol  # mouse
# echo 1 > functions/hid.usb1/subclass  # boot interface subclass
# echo 3 > functions/hid.usb1/report_length  # TODO - figure out how to compute this. currently looks like setting it too high causes irq errors on the usb host, but setting it too small might just be fine? maybe parse the report descriptor and pick the smallest report the device says it can send?
## Copied from `sudo usbhid-dump -m 046d:c52b -ed`
# cp /sys/class/hidraw/hidraw1/device/report_descriptor functions/hid.usb1/report_desc
# ln -s functions/hid.usb1 configs/c.1/
# End functions

# ls /sys/class/udc > UDC
EOF
    sudo chmod +x /etc/rc.local.d/*.sh
}

enable_kernel_modules
create_etc_rc_local
create_gadget_setup_script
