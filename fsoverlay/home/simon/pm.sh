#!/bin/sh
# sh pm.sh [performance|schedutil|ondemand]   (sudo behövs för scaling_governor)
G=${1:-performance}
for c in /sys/devices/system/cpu/cpu[0-9]*; do
	echo $G > $c/cpufreq/scaling_governor
done
for c in /sys/devices/system/cpu/cpu[0-9]*; do
	printf "%s %s %s kHz\n" $(basename $c) "$(cat $c/cpufreq/scaling_governor)" "$(cat $c/cpufreq/scaling_cur_freq)"
done
