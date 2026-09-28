#!/bin/sh
# 7-mic-route.sh  (sudo) - inbyggd mikrofon -> EP1 TX -> hw:0,8 (samma mixrar som 6-mic.sh, utan inspelning)
amixer -c0 cset name="Audio Capture Mic Source" Builtin_MIC
amixer -c0 cset name="Mic Spatial Module Enable" 1
amixer -c0 cset name="BUILDIN MIC ID CAPTURE LIST" 0,1,2,-1
amixer -c0 cset name="MIC DC Blocker" 1
amixer -c0 cset name="EP1 TX Mixer INTERNAL_MIC_TX" 1
