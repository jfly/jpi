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
EOF
    sudo chmod +x /etc/rc.local.d/*.sh
}

enable_kernel_modules
create_etc_rc_local
create_gadget_setup_script
