import subprocess

import xbmc

# Basic idea from https://discourse.osmc.tv/t/turn-tv-on-cec-when-playing-a-video-solved/7446/5

class Player(xbmc.Player):
    def onAVStarted(self):
        if self.isPlayingVideo():
            xbmc.log("Looks like you just started playing a video. Attemping to turn on the tv and the receiver")
            subprocess.check_call("/storage/tv-on.sh")
        else:
            xbmc.log("Looks like you just started playing audio (no video). Attemping to turn on just the receiver")
            subprocess.check_call("/storage/receiver-on.sh")

player = Player()
mon = xbmc.Monitor()

while not mon.waitForAbort(10):
    pass
