#!/usr/bin/env bash

set -e

systemctl stop kodi
# parsecd relies upon these environment variables to look up its configuration.
# When run via systemd-run, these environment variables aren't set, so we have
# to hackily set them here.
USER=root LOGNAME=root HOME=/storage /usr/bin/parsecd

systemctl start kodi
