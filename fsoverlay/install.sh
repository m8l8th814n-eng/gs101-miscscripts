#!/bin/sh
# Kör på enheten:  sudo sh ~/rootfs-overlay/install.sh
# (kopiera först: scp -r ~/pmbootstrap/rootfs-overlay simon@172.16.42.1:~/)
set -e
D=$(dirname "$0")
cp -a $D/lib/firmware/. /lib/firmware/
cp $D/etc/modprobe.d/aoc-trusty.conf $D/etc/modprobe.d/trusty-order.conf $D/etc/modprobe.d/blacklist-brcmfmac.conf /etc/modprobe.d/
mkdir -p /etc/NetworkManager/conf.d /etc/pulse/default.pa.d /etc/local.d
cp $D/etc/NetworkManager/conf.d/99-gs101-wifi.conf $D/etc/NetworkManager/conf.d/98-wifi-nopowersave.conf /etc/NetworkManager/conf.d/
cp $D/etc/pulse/default.pa.d/aoc-speaker.pa $D/etc/pulse/default.pa.d/aoc-mic.pa /etc/pulse/default.pa.d/
cp $D/etc/local.d/aoc-audio.start $D/etc/local.d/wifi-noaspm.start /etc/local.d/ && chmod +x /etc/local.d/aoc-audio.start /etc/local.d/wifi-noaspm.start
# mkdir -p /home/simon/ljud
# cp $D/home/simon/ljud/*.sh /home/simon/ljud/
# cp $D/home/simon/speaker.cal $D/home/simon/pm.sh /home/simon/
# chown -R simon:simon /home/simon/ljud /home/simon/speaker.cal
echo "klart - glom inte: sudo apk add rtkit; rc-update add rtkit default"
