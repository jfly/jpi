#!/usr/bin/env python

import rxv
import sys

rx = rxv.RXV("http://receiver/YamahaRemoteControl/ctrl")
rx.scenes() # Workaround for https://github.com/wuub/rxv/pull/90
rx.scene = sys.argv[1]
