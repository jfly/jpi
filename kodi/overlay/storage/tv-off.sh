#!/usr/bin/env bash

set -e

echo 'standby 5' | cec-client -s -d 1
echo 'standby 0' | cec-client -s -d 1
