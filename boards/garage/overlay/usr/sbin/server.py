#!/usr/bin/micropython

import time

from machine import Pin
from noggin import HTTPError, Noggin, Response

# class CompatPin:
#     OUT = "out"
#     IN = "in"
#     def __init__(self, pin_id, direction):
#         self._pin_id = pin_id
#         self._direction = direction
#         self._value = {
#             'high': 1,
#             'low': 0,
#         }[self._direction]
#
#     def value(self, new_value=None):
#         if new_value is None:
#             return self._value
#         self._value = new_value
#
# Pin = CompatPin

class InitializablePin(Pin):
    '''
    Pin subclass with support for setting an initial output value.
    Basic idea from http://codefoster.com/pi-basicgpio/.
    I don't know why MicroPython doesn't have support for this by default.
    '''
    HIGH = "high"
    LOW = "low"

    def __init__(self, pin_id, direction, initial_value=None):
        if initial_value is not None and direction == Pin.OUT:
            if initial_value:
                direction = self.HIGH
            else:
                direction = self.LOW

        super().__init__(pin_id, direction)

class Relay(InitializablePin):
    '''
    Represents a relay which can be turned on or off. Saves you from having
    to think about if this is an active high or active low relay.
    '''
    def __init__(self, pin_id, active_low):
        self._active_low = active_low
        super().__init__(pin_id, Pin.OUT, initial_value=self._inactive_value)

    def on(self):
        ''' Activate the relay. '''
        self.value(self._active_value)

    def off(self):
        ''' Deactivate the relay. '''
        self.value(self._inactive_value)

    def is_on(self):
        ''' Returns if the relay is on or off. '''
        return bool(self.value()) == self._active_value

    @property
    def _active_value(self):
        return not self._active_low

    @property
    def _inactive_value(self):
        return not self._active_value


GARAGE_DOOR_RELAY = Relay(4, active_low=False)
GARAGE_DOOR_SENSOR = Pin(22)

app = Noggin()

@app.route('/garage/toggle', methods=['POST'])
def toggle_garage(req):
    ''' Toggle the state of the garage door. '''
    GARAGE_DOOR_RELAY.on()
    time.sleep(0.2)
    GARAGE_DOOR_RELAY.off()
    return garage_status_json()

@app.route('/garage', methods=['GET'])
def garage(req):
    ''' Get the status of the garage door (open or closed). '''
    return garage_status_json()

def garage_status_json():
    ''' Jsonifies the status of the garage door. '''
    return {'status': 'closed' if GARAGE_DOOR_SENSOR.value() else 'open'}


if __name__ == "__main__":
    app.serve(port=80)
