#!/usr/bin/env bash

curl -H "Content-type: application/json" -X POST -d '{"jsonrpc":"2.0","method":"Settings.GetSettingValue", "params":{"setting":"audiooutput.audiodevice"},"id":1}' http://localhost:8080/jsonrpc
echo ""
