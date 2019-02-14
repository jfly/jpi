#!/usr/bin/env python3

import os
import sys
import time
import signal
from os.path import join
from collections import namedtuple

def main():
    signal.signal(signal.SIGINT, exit_gracefully)
    signal.signal(signal.SIGTERM, exit_gracefully)

    kernel_name = sys.argv[1]

    print("Handling new HID device: {}.".format(kernel_name))
    device_info = get_device_info(kernel_name)
    print(device_info.uevent)

    gadget_info = create_gadget_function(device_info)

    proxy_forever(device_info, gadget_info)

DeviceInfo = namedtuple('DeviceInfo', ['uevent', 'report_descriptor', 'hidraw_path'])

def get_device_info(kernel_name) -> DeviceInfo:
    device_path = join("/sys/bus/hid/devices/", kernel_name)

    with open(join(device_path, "uevent")) as f:
        uevent = Uevent.parse(f.read())

    with open(join(device_path, "report_descriptor"), 'rb') as f:
        report_descriptor = f.read()
        # TODO - This is a mystery to me. When connecting my bluetooth
        # keyboard, I see a report descriptor that ends in "c0 00".
        # If we blindly copy that report descriptor, and then try to connect to
        # a Windows box, I see the following error in Device Manager:
        #  This device cannot start. (Code 10)
        #  An unknown item was found in the report descriptor.
        # https://eleccelerator.com/usbdescreqparser/ says that this trailing 00 is
        # "Unknown (bTag: 0x00, bType: 0x00)", so that's a little consistent.
        # Removing the trailing 00 seems to make things work well on Windows.
        if report_descriptor[-1] == 0:
            report_descriptor = report_descriptor[:-1]

    # There's this hidraw directory, which contains a folder named hidrawN
    # So far I've only ever seen one hidrawN folder, so we just pick the one
    # that's there. There's probably a better way of doing this...
    hidraw_dir = join(device_path, "hidraw")
    hidraw_name = get_only_element(os.listdir(hidraw_dir))
    with open(join(device_path, hidraw_dir, hidraw_name, "dev")) as f:
        char_addr = f.read().strip()
    hidraw_path = join("/dev/char/", char_addr)

    return DeviceInfo(
        uevent=uevent,
        report_descriptor=report_descriptor,
        hidraw_path=hidraw_path,
    )

class Uevent(namedtuple('Uevent', ['driver', 'hid_id', 'hid_name', 'hid_phys', 'hid_uniq', 'modalias'])):
    @classmethod
    def parse(cls, data):
        kwargs = {}
        for line in data.split("\n"):
            if line:
                key, value = line.split("=", 1)
                kwargs[key.lower()] = value
        return cls(**kwargs)

GadgetInfo = namedtuple('GadgetInfo', ['hidg_path'])

def create_gadget_function(device_info: DeviceInfo) -> GadgetInfo:
    # Add a function to the system's usb gadget to emulate the given device.
    # The system's usb gadget was created on boot by /etc/rc.local.d/setup_gadget.sh.
    gadget_dir = "/sys/kernel/config/usb_gadget/hidproxy"

    nth_function = 0
    while True:
        function_name = "hid.usb{}".format(nth_function)
        function_dir = join(gadget_dir, "functions", function_name)
        try:
            os.mkdir(function_dir)
            # Success! We created the directory, so break out.
            break
        except FileExistsError:
            # That folder already existed, so lets increment and try again.
            nth_function += 1

    with open(join(function_dir, "protocol"), "w") as f:
        # According to
        # https://www.usb.org/sites/default/files/documents/hid1_11.pdf, "The
        # bInterfaceProtocol member of an Interface descriptor only has meaning
        # if the bInterfaceSubClass member declares that the device supports a
        # boot interface, otherwise it is 0"
        # I'm just setting this to "1" for keyboard, so the keyboard can work in the bios.
        # I'm not sure if there are any downsides to this.
        f.write("1")

    with open(join(function_dir, "subclass"), "w") as f:
        f.write("1") # boot interface subclass

    with open(join(function_dir, "report_length"), "w") as f:
        # TODO - Figure out what should go here. It looks like setting
        # it too high causes irq errors on the usb host, but setting it too
        # low might just be fine? Maybe we should parse the report descriptor and pick
        # the smallest report the device says it can send?
        # For now, I've set this to 7 because I just happen to know that my
        # mouse causes IRQ errors on my laptop if I use 8, and 7 seems to work
        # fine with my keyboard.
        f.write("7")

    with open(join(function_dir, "report_desc"), "wb") as f:
        f.write(device_info.report_descriptor)

    udc_path = join(gadget_dir, "UDC")
    def disable_gadget():
        with open(udc_path, "r+") as f:
            udc_contents = f.read()
            # If the gadget is already disabled, then don't try to re-disable it, because that errors out.
            if udc_contents != "\n":
                f.seek(0)
                f.write("\n")
                f.truncate()

    # First disable the usb gadget before adding a function to it.
    disable_gadget()

    # Now add the function.
    symlink_name = join(gadget_dir, "configs/c.1/", function_name)
    os.symlink(function_dir, symlink_name)

    # Finally, re-enable the usb gadget.
    # Copied from "Creating the gadget" on http://isticktoit.net/?p=1383
    udc_contents = get_only_element(os.listdir("/sys/class/udc"))
    with open(udc_path, "w") as f:
        f.write(udc_contents)

    with open(join(function_dir, "dev"), "r") as f:
        char_addr = f.read().strip()
    hidg_device_path = join("/dev/char/", char_addr)
    wait_for(lambda: os.path.exists(hidg_device_path), desc="{} to exist".format(hidg_device_path))

    def cleanup():
        disable_gadget()
        os.unlink(symlink_name)
        os.rmdir(function_dir)
    exit_funcs.append(cleanup)

    return GadgetInfo(
        hidg_path=hidg_device_path,
    )

def proxy_forever(device_info, gadget_info):
    print("Proxying forever from {} to {}".format(device_info.hidraw_path, gadget_info.hidg_path))
    with open(gadget_info.hidg_path, 'rb+') as out_f:
        in_fd = os.open(device_info.hidraw_path, os.O_RDWR)
        maybe_fixup_device(device_info, in_fd)
        while True:
            buf = os.read(in_fd, 9) # TODO: I'm not sure what buffer size to actually put here...
            out_f.write(buf)
            out_f.flush()

def maybe_fixup_device(device_info, in_fd):
    """Some devices need special initialization. This is the place to do that."""

    # Turn on FnLk for ThinkPad Bluetooth Keyboard.
    # Trick copied from https://github.com/lentinj/tp-compact-keyboard/blob/e8fff5088a3e1ef22e9d6b25d1b3f211db58b555/tp-compact-keyboard#L58.
    if device_info.uevent.hid_name == "ThinkPad Compact Bluetooth Keyboard with TrackPoint":
        os.write(in_fd, b"\x18\x05\x01")

def get_only_element(arr):
    arr = list(arr)
    assert len(arr) == 1
    return arr[0]

def wait_for(func, desc, timeout_seconds=1*60):
    if func():
        return

    start = time.time()
    print("Waiting for {}".format(desc), end="")
    sys.stdout.flush()
    while True:
        if func():
            print("done!")
            return

        if (time.time() - start) > timeout_seconds:
            print("timeout!")
            assert False

        print(".", end="")
        sys.stdout.flush()
        time.sleep(1)

exit_funcs = []
def exit_gracefully(_signum, _frame):
    print("Exiting... ", end="")
    for func in exit_funcs:
        func()
    print("Goodbye!")
    os._exit(0)

if __name__ == "__main__":
    main()
