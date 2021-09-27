#!/usr/bin/micropython

import glob
import json
import os.path
import socket
import traceback

# Copied (and modified) from
# https://docs.micropython.org/en/latest/esp8266/tutorial/network_tcp.html#simple-http-server

def get_temperatures_celsius():
    temperature_by_name = {}
    for temperature_file in glob.glob("/sys/bus/w1/devices/*/temperature"):
        name = os.path.basename(os.path.dirname(temperature_file))
        with open(temperature_file, "r", encoding="utf-8") as f_temp:
            temperature_str = f_temp.read().strip()
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
        client, addr = s.accept()
        try:
            print('client connected from', addr)
            cl_file = client.makefile('rwb', 0)
            while True:
                line = cl_file.readline()
                if not line or line == b'\r\n':
                    break

            response, content_type = handle_request()
            if content_type == "application/json":
                response = json.dumps(response)
            client.send('HTTP/1.0 200 OK\r\nContent-type: %s\r\n\r\n' % content_type)
            client.send(response)
        except Exception: # pylint: disable=broad-except
            # Don't crash the server, but do print out information about the
            # exception.
            traceback.print_exc()
        finally:
            client.close()

if __name__ == "__main__":
    main()
