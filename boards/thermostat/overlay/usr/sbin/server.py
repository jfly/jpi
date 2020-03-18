#!/usr/bin/micropython

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


FAN_RELAY = Relay(17, active_low=True)
FURNACE_RELAY = Relay(18, active_low=True)

app = Noggin()

@app.route('/fan/on', methods=['POST'])
def fan_on(req):
    ''' Turn on the fan. '''
    FAN_RELAY.on()
    return relay_status_json(FAN_RELAY)

@app.route('/fan/off', methods=['POST'])
def fan_off(req):
    ''' Turn off the fan. '''
    FAN_RELAY.off()
    return relay_status_json(FAN_RELAY)

@app.route('/fan', methods=['GET'])
def fan(req):
    ''' Get the status of the fan. '''
    return relay_status_json(FAN_RELAY)

@app.route('/furnace/on', methods=['POST'])
def furnace_on(req):
    ''' Turn on the furnace. '''
    FURNACE_RELAY.on()
    return relay_status_json(FURNACE_RELAY)

@app.route('/furnace/off', methods=['POST'])
def furnace_off(req):
    ''' Turn off the furnace. '''
    FURNACE_RELAY.off()
    return relay_status_json(FURNACE_RELAY)

@app.route('/furnace', methods=['GET'])
def furnace(req):
    ''' Get the status of the furnace. '''
    return relay_status_json(FURNACE_RELAY)

def relay_status_json(relay):
    ''' Jsonifies the status of the given relay. '''
    return {'status': 'on' if relay.is_on() else 'off'}


if __name__ == "__main__":
    app.serve(port=80)
