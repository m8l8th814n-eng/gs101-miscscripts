#!/bin/sh
# sh 2-pulse.sh   (som simon, INTE sudo)
pactl set-card-profile alsa_card.platform-sound-aoc output:stereo-fallback
pactl set-default-sink alsa_output.platform-sound-aoc.stereo-fallback
pactl info | grep "Default Sink"
