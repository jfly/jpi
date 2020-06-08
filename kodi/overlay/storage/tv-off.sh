#!/usr/bin/env bash

echo 'standby 5' | cec-client -s -d 1
echo 'standby 0' | cec-client -s -d 1
