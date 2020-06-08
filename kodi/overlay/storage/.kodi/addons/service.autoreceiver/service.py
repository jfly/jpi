import time
import xbmc
import subprocess

# Service that will detect when audio or video start playing, and turn on the reciever/tv as appropriate.
# Basic idea from https://discourse.osmc.tv/t/turn-tv-on-cec-when-playing-a-video-solved/7446/5

def main():
    player = Player()
    monitor = xbmc.Monitor()

    while not monitor.abortRequested():
        # Sleep/wait for abort for 10 seconds
        if monitor.waitForAbort(10):
            # Abort was requested while waiting. We should exit
            break


class Player(xbmc.Player):
    def onAVStarted(self):
        if self.isPlayingVideo():
            xbmc.log("Looks like you just started playing a video. Attemping to turn on the tv and the receiver", level=xbmc.LOGNOTICE)
            subprocess.check_call("/storage/tv-on.sh")
        else:
            xbmc.log("Looks like you just started playing audio (no video). Attemping to turn on just the receiver", level=xbmc.LOGNOTICE)
            subprocess.check_call("/storage/receiver-on.sh")

if __name__ == '__main__':
    main()
