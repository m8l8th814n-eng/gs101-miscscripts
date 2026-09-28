amixer -c0 cset name="PCM Source" ASP
amixer -c0 cset name="R PCM Source" ASP
aplay -D hw:0,5 --period-size=960 --buffer-size=3840 /usr/share/sounds/alsa/Front_Center.wav
