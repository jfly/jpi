#!/usr/bin/env bash

if [ $# -lt 1 ]; then
  echo "USAGE: `basename $0` OUTPUTDEVICE"
  exit 1
fi

DEVICE=$1
curl -s -H "Content-type: application/json" -X POST -d '{"jsonrpc":"2.0","method":"Settings.SetSettingValue", "params":{"setting":"audiooutput.audiodevice","value":"'"$DEVICE"'"},"id":1}' http://dallben:8080/jsonrpc > /dev/null
