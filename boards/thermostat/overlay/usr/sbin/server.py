#!/usr/bin/micropython

#<<< from machine import Pin
#<<<
#<<< FAN_PIN = Pin(17, mode=Pin.OUT, value=True)
#<<< FURNACE_PIN = Pin(18, mode=Pin.OUT, value=True)

from noggin import HTTPError, Noggin, Response

app = Noggin()

@app.route('/echo2', methods=['PUT', 'POST'])
def echo2(req):
    '''Like echo1, but implemented with memory-efficient iterables so
    that it should work regardless of the size of the request.'''
    yield from req.iter_content()


@app.route('/device/([^/]+)/([^/]+)')
def parameters(req, p1, p2):
    '''Match groups in the route will be passed to your function as
    positional parameters.'''

    return {'p1': p1, 'p2': p2}


if __name__ == "__main__":
    app.serve(port=8080)
