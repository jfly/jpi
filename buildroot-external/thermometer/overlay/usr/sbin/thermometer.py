#!/usr/bin/micropython

import glob
import json
import os.path
import socket

# Copied (and modified) from
# https://docs.micropython.org/en/latest/esp8266/tutorial/network_tcp.html#simple-http-server

def get_temperatures_celsius():
    temperature_by_name = {}
    for temperature_file in glob.glob("/sys/class/hwmon/hwmon*/temp1_input"):
        device_name_file = os.path.join(os.path.dirname(temperature_file), "device/name")
        with open(temperature_file, "r") as f_temp, open(device_name_file, "r") as f_name:
            temperature_str = f_temp.read().strip()
            name = f_name.read().strip()
        temperature_celsius = int(temperature_str)/1000
        temperature_by_name[name] = temperature_celsius

    return temperature_by_name

def c_to_f(c):
    return c * (9/5) + 32

def handle_request():
    data = {
        name: {
            "celsius": celsius,
            "fahrenheit": c_to_f(celsius),
        } for name, celsius in get_temperatures_celsius().items()
    }
    return data, "application/json"

def main():
    addr = socket.getaddrinfo('0.0.0.0', 80)[0][-1]

    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) #<<<
    s.bind(addr)
    s.listen(1)

    print('listening on', addr)

    while True:
        cl, addr = s.accept()
        print('client connected from', addr)
        cl_file = cl.makefile('rwb', 0)
        while True:
            line = cl_file.readline()
            if not line or line == b'\r\n':
                break

        response, content_type = handle_request()
        if content_type == "application/json":
            response = json.dumps(response)
        cl.send('HTTP/1.0 200 OK\r\nContent-type: %s\r\n\r\n' % content_type)
        cl.send(response)
        cl.close()

if __name__ == "__main__":
    main()
