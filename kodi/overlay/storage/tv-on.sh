#!/usr/bin/env bash

./auto-audio.sh
python /storage/receiver/__main__.py BD/DVD
#echo 'on 0' | cec-client -s -d 1
#echo 'on 5' | cec-client -s -d 1
