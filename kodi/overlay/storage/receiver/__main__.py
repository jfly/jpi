#!/usr/bin/env python

import rxv
import sys

rx = rxv.RXV("http://receiver/YamahaRemoteControl/ctrl")
rx.scenes() # Workaround for the fact that assertions are disabled in OpenElec python
rx.scene = sys.argv[1]
