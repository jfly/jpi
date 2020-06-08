#!/usr/bin/env bash

systemctl stop kodi
# When run via systemd-run, `USER` and `HOME` are not set.
USER=root HOME=/storage /usr/bin/parsecd
systemctl start kodi
