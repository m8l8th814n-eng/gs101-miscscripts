#!/bin/sh
# strobe-v4l2.sh [torch|flash] -- LM3644 via its V4L2 flash subdev (bus 3 @0x63, driver lm3644).
# The old strobe.sh wrote I2C bus 2, where nothing answers at 0x63.
S=$(for s in /dev/v4l-subdev*; do grep -q lm3644-led0 /sys/class/video4linux/$(basename $s)/name && echo $s; done | head -1)
case "${1:-torch}" in
  torch) v4l2-ctl -d $S --set-ctrl=intensity_torch_mode=50000 --set-ctrl=led_mode=2; sleep 0.1; v4l2-ctl -d $S --set-ctrl=led_mode=0;;
  flash) v4l2-ctl -d $S --set-ctrl=strobe_source=0 --set-ctrl=strobe_timeout=100 --set-ctrl=intensity_flash_mode=300000 --set-ctrl=led_mode=1 --set-ctrl=strobe=1; sleep 0.2; v4l2-ctl -d $S --set-ctrl=led_mode=0;;
esac
v4l2-ctl -d $S --get-ctrl=faults
