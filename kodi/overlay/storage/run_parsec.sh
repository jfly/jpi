#!/usr/bin/env bash

set -e

PARSEC_SETTINGS=""
# Automatically connect to gurgi
PARSEC_SETTINGS="$PARSEC_SETTINGS:peer_id=1xmZ7t6z5geMD0zZcv0zDWlQBsp"
PARSEC_SETTINGS="$PARSEC_SETTINGS:client_vsync=0"
PARSEC_SETTINGS="$PARSEC_SETTINGS:client_overlay=0"

systemctl stop kodi
# parsecd relies upon these environment variables to look up its configuration.
# When run via systemd-run, these environment variables aren't set, so we have
# to hackily set them here.
# Note that we don't care if parsec exits with an error, we still want to start
# kodi after it exits.
USER=root LOGNAME=root HOME=/storage /usr/bin/parsecd "$PARSEC_SETTINGS" || true

systemctl start kodi
