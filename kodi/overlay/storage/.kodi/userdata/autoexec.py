import json
import subprocess

import xbmc

# Enable the plugins we know we've installed.
# TODO: Looks like we might be able to switch to this in v19 (https://kodi.wiki/view/List_of_built-in_functions#Add-on_built-in.27s): xbmc.executebuiltin('EnableAddon("script.parsec")')
addons_to_enable = [
    "script.parsec",
    "service.autoreceiver",
    "service.subtitles.opensubtitles_by_opensubtitles",
]
for addon in addons_to_enable:
    cmd_json = {
        "jsonrpc": "2.0",
        "id": "insideautoexec",
        "method": "Addons.SetAddonEnabled",
        "params": {
            "addonid": addon,
            "enabled": True,
        },
    }
    xbmc.executeJSONRPC(json.dumps(cmd_json))

addons_to_install = [
    "script.tubecast",
    "game.libretro.snes9x",
    "game.libretro.atari800",
    "game.controller.atari.5200",
]
for addon in addons_to_install:
    xbmc.executebuiltin("InstallAddon({})".format(addon))
