#!/bin/sh
# sh 1-setup.sh   (slutar med amp PÅ)
#amixer -c0 cset name="Main AMP Enable Switch" 0
#amixer -c0 cset name="R Main AMP Enable Switch" 0

amixer -c0 cset name="TDM_0_RX Chan" Four
amixer -c0 cset name="TDM_0_TX Chan" Four
amixer -c0 cset name="TDM_0_RX Format" S32_LE
amixer -c0 cset name="TDM_0_TX Format" S32_LE

amixer -c0 cset name="ASPRX1 Slot Position" 0
amixer -c0 cset name="ASPRX2 Slot Position" 1
amixer -c0 cset name="R ASPRX1 Slot Position" 1
amixer -c0 cset name="R ASPRX2 Slot Position" 0
amixer -c0 cset name="DSP RX1 Source" ASPRX1
amixer -c0 cset name="DSP RX2 Source" ASPRX1
amixer -c0 cset name="R DSP RX1 Source" ASPRX1
amixer -c0 cset name="R DSP RX2 Source" ASPRX1
amixer -c0 cset name="ASP TX1 Source" VMON
amixer -c0 cset name="ASP TX2 Source" IMON
amixer -c0 cset name="R ASP TX1 Source" VMON
amixer -c0 cset name="R ASP TX2 Source" IMON

amixer -c0 cset name="Boost Peak Current Limit" 1.70A
amixer -c0 cset name="R Boost Peak Current Limit" 1.90A
amixer -c0 cset name="Digital PCM Volume" 817
amixer -c0 cset name="R Digital PCM Volume" 817
amixer -c0 cset name="AMP PCM Gain" 17
amixer -c0 cset name="R AMP PCM Gain" 17

amixer -c0 cset name="TDM_0_RX Mixer EP1" on
amixer -c0 cset name="TDM_0_RX Mixer EP6" on
amixer -c0 cset name="TDM_0_RX Mixer EP2" on
amixer -c0 cset name="I2S_0_RX Mixer EP1" off
amixer -c0 cset name="I2S_0_RX Mixer EP6" off
amixer -c0 cset name="I2S_1_RX Mixer EP1" off
amixer -c0 cset name="I2S_1_RX Mixer EP6" off

amixer -c0 cset name="DSP1 Preload Switch" 0
amixer -c0 cset name="R DSP1 Preload Switch" 0
sleep 2
amixer -c0 cset name="DSP1 Firmware" Protection
amixer -c0 cset name="R DSP1 Firmware" Protection
amixer -c0 cset name="DSP1 Preload Switch" 1
amixer -c0 cset name="R DSP1 Preload Switch" 1
sleep 4

amixer -c0 cset name="DSP1 Protection cd CAL_R"          0x00,0x00,0x1f,0x6c
amixer -c0 cset name="DSP1 Protection cd CAL_STATUS"     0x00,0x00,0x00,0x01
amixer -c0 cset name="DSP1 Protection cd CAL_CHECKSUM"   0x00,0x00,0x1f,0x6d
amixer -c0 cset name="DSP1 Protection cd CAL_AMBIENT"    0x00,0x00,0x00,0x1c
amixer -c0 cset name="R DSP1 Protection cd CAL_R"        0x00,0x00,0x22,0xe6
amixer -c0 cset name="R DSP1 Protection cd CAL_STATUS"   0x00,0x00,0x00,0x01
amixer -c0 cset name="R DSP1 Protection cd CAL_CHECKSUM" 0x00,0x00,0x22,0xe7
amixer -c0 cset name="R DSP1 Protection cd CAL_AMBIENT"  0x00,0x00,0x00,0x1c
amixer -c0 cset name="Firmware Reload Tuning" 1
amixer -c0 cset name="R Firmware Reload Tuning" 1
sleep 1

amixer -c0 cset name="PCM Source" ASP
#amixer -c0 cset name="PCM Source" DSP
amixer -c0 cset name="R PCM Source" ASP
#amixer -c0 cset name="R PCM Source" DSP

amixer -c0 cset name="Main AMP Enable Switch" 1
amixer -c0 cset name="R Main AMP Enable Switch" 1
