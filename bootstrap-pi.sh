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
mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol  # keyboard
echo 1 > functions/hid.usb0/subclass  # boot interface subclass
echo 8 > functions/hid.usb0/report_length
# Nice explanation of this report descriptor here: https://github.com/jpbrucker/BLE_HID/blob/master/doc/HID.md
# This differs very slightly from http://www.rennes.supelec.fr/ren/fi/elec/docs/usb/hid1_11.pdf, which declard the "Output (Constant)" slightly differently for the LED report padding.
# https://www.rmedgar.com/blog/using-rpi-zero-as-keyboard-report-descriptor explains that the padding bits are to make sure the full output report adds up to 1 byte.
echo -ne \\x05\\x01\\x09\\x06\\xa1\\x01\\x05\\x07\\x19\\xe0\\x29\\xe7\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02\\x95\\x01\\x75\\x08\\x81\\x03\\x95\\x05\\x75\\x01\\x05\\x08\\x19\\x01\\x29\\x05\\x91\\x02\\x95\\x01\\x75\\x03\\x91\\x03\\x95\\x06\\x75\\x08\\x15\\x00\\x25\\x65\\x05\\x07\\x19\\x00\\x29\\x65\\x81\\x00\\xc0 > functions/hid.usb0/report_desc
ln -s functions/hid.usb0 configs/c.1/

mkdir -p functions/hid.usb1
echo 2 > functions/hid.usb1/protocol  # mouse
echo 1 > functions/hid.usb1/subclass  # boot interface subclass
echo 8 > functions/hid.usb1/report_length
# Copied from `sudo usbhid-dump -m 046d:c52b -ed`
echo -ne \\x05\\x01\\x09\\x02\\xA1\\x01\\x09\\x01\\xA1\\x00\\x05`
	`\\x09\\x19\\x01\\x29\\x03\\x15\\x00\\x25\\x01\\x95\\x03`
	`\\x75\\x01\\x81\\x02\\x95\\x01\\x75\\x05\\x81\\x01\\x05`
	`\\x01\\x09\\x30\\x09\\x31\\x15\\x81\\x25\\x7F\\x75\\x08`
	`\\x95\\x02\\x81\\x06\\xC0\\xC0 > functions/hid.usb1/report_desc
#echo " 05 01 09 02 A1 01 85 02 09 01 A1 00 05 09 19 01
 #29 10 15 00 25 01 95 10 75 01 81 02 05 01 16 01
 #F8 26 FF 07 75 0C 95 02 09 30 09 31 81 06 15 81
 #25 7F 75 08 95 01 09 38 81 06 05 0C 0A 38 02 95
 #01 81 06 C0 C0 05 0C 09 01 A1 01 85 03 75 10 95
 #02 15 01 26 8C 02 19 01 2A 8C 02 81 00 C0 05 01
 #09 80 A1 01 85 04 75 02 95 01 15 01 25 03 09 82
 #09 81 09 83 81 60 75 06 81 03 C0 06 BC FF 09 88
 #A1 01 85 08 19 01 29 FF 15 01 26 FF 00 75 08 95
 #01 81 00 C0" | xxd -r -p > functions/hid.usb1/report_desc
ln -s functions/hid.usb1 configs/c.1/
# End functions

ls /sys/class/udc > UDC
EOF
    sudo chmod +x /etc/rc.local.d/*.sh
}

enable_kernel_modules
create_etc_rc_local
create_gadget_setup_script
