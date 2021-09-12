#!/usr/bin/env bash

set -e

./auto-audio.sh
python /storage/receiver/__main__.py NET
#echo 'on 0' | cec-client -s -d 1
#echo 'on 5' | cec-client -s -d 1
