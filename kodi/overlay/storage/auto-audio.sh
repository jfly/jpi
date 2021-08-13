#!/usr/bin/env bash

# Check if bose headphones are connected. If so, switch to pulseaudio. If not, switch to HDMI.
if bluetoothctl info 28:11:A5:36:83:33 | grep "Connected: yes" > /dev/null; then
  echo "Detected connected headphones"
  ./set-audio.sh 'PULSE:Default'
else
  echo "No headphones detected"
  ./set-audio.sh 'PI:HDMI'
fi

echo -n "Audio output is now: "
./get-audio.sh
