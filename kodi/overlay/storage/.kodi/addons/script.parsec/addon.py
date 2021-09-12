import os

import xbmcgui

xbmcgui.Dialog().notification(
    heading="Parsec",
    message="Starting Parsec!",
    time=5000,
)

# Note that we run this with systemd-run, because the script actually stops
# kodi, and we're currently inside of kodi. Thus, if we just ran the script, it
# would actually end up killing itself midway through.
os.system("systemd-run /storage/run_parsec.sh")
