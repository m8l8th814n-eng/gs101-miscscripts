#!/bin/sh
# sh status.sh   (läser bara)
amixer -c0 cget name="Main AMP Enable Switch" | tail -1
amixer -c0 cget name="R Main AMP Enable Switch" | tail -1
amixer -c0 cget name="PCM Source" | tail -1
amixer -c0 cget name="DSP1 Preload Switch" | tail -1
amixer -c0 cget name="DSP1 Protection cd CAL_R" | tail -1
amixer -c0 cget name="R DSP1 Protection cd CAL_R" | tail -1
amixer -c0 cget name="TDM_0_RX Mixer EP1" | tail -1
amixer -c0 cget name="TDM_0_RX Mixer EP6" | tail -1
pactl info | grep "Default Sink"
grep -A2 '"audio_output_control"' /sys/devices/platform/soc@0/19000000.aoc/services
