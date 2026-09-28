#!/bin/sh
# tiiiiiiiiiiiiiiime for calibration! come on!

C=0
CAL="${CAL:-$HOME/speaker.cal}"
s(){ amixer -c$C cset name="$1" "$2" >/dev/null 2>&1 || echo "  ! misslyckades: $1 = $2"; }
g(){ amixer -c$C cget name="$1" 2>/dev/null | sed -n 's/.*: values=//p'; }
be(){ printf '0x%02x,0x%02x,0x%02x,0x%02x' $(( ($1>>24)&255 )) $(( ($1>>16)&255 )) $(( ($1>>8)&255 )) $(( $1&255 )); }

calvals() {
	if [ -r "$CAL" ]; then
		set -- $(od -An -tu4 -v "$CAL")
		L_R=$1; L_ST=$2; L_CK=$3; L_AMB=$4
		R_R=$7; R_ST=$8; R_CK=$9; R_AMB=${10}
		echo "  cal från $CAL: L CAL_R=$L_R R CAL_R=$R_R ambient=$L_AMB"
	else
		L_R=8044; L_ST=1; L_CK=8045; L_AMB=28
		R_R=8934; R_ST=1; R_CK=8935; R_AMB=28
		echo "  cal: inbyggda fabriksvärden (L 0x1f6c, R 0x22e6)"
	fi
}

reload_fw() {
	s "DSP1 Preload Switch" 0;   s "R DSP1 Preload Switch" 0;   sleep 2
	s "DSP1 Firmware" "$1";       s "R DSP1 Firmware" "$1"
	s "DSP1 Preload Switch" 1;   s "R DSP1 Preload Switch" 1;   sleep 4
}

bus() {
	s "TDM_0_RX Chan" Four;        s "TDM_0_TX Chan" Four
	s "TDM_0_RX Format" S32_LE;    s "TDM_0_TX Format" S32_LE
	s "ASPRX1 Slot Position" 0;    s "ASPRX2 Slot Position" 1
	s "R ASPRX1 Slot Position" 1;  s "R ASPRX2 Slot Position" 0
	s "DSP RX1 Source" ASPRX1;     s "R DSP RX1 Source" ASPRX1
	s "DSP RX2 Source" ASPRX1;     s "R DSP RX2 Source" ASPRX1
	s "ASP TX1 Source" VMON;       s "ASP TX2 Source" IMON
	s "R ASP TX1 Source" VMON;     s "R ASP TX2 Source" IMON
	s "Boost Peak Current Limit" 1.70A;  s "R Boost Peak Current Limit" 1.90A
	s "Digital PCM Volume" 817;    s "R Digital PCM Volume" 817
	s "AMP PCM Gain" 17;           s "R AMP PCM Gain" 17
}

route() {
	s "TDM_0_RX Mixer EP1" on
	s "TDM_0_RX Mixer EP6" on
	s "I2S_0_RX Mixer EP1" off
}

cal_apply() {
	calvals
	s "DSP1 Protection cd CAL_R"          "$(be $L_R)"
	s "DSP1 Protection cd CAL_STATUS"     "$(be $L_ST)"
	s "DSP1 Protection cd CAL_CHECKSUM"   "$(be $L_CK)"
	s "DSP1 Protection cd CAL_AMBIENT"    "$(be $L_AMB)"
	s "R DSP1 Protection cd CAL_R"        "$(be $R_R)"
	s "R DSP1 Protection cd CAL_STATUS"   "$(be $R_ST)"
	s "R DSP1 Protection cd CAL_CHECKSUM" "$(be $R_CK)"
	s "R DSP1 Protection cd CAL_AMBIENT"  "$(be $R_AMB)"
	for n in $(amixer -c$C controls | grep -i 'Reload Tuning' | sed -n 's/^numid=\([0-9]*\),.*/\1/p'); do
		amixer -c$C cset numid=$n 1 >/dev/null 2>&1
	done
	sleep 1
}

amp(){ s "Main AMP Enable Switch" "$1"; s "R Main AMP Enable Switch" "$1"; }

setup() {
	amp 0
	bus
	route
	reload_fw Protection
	cal_apply
	s "PCM Source" DSP; s "R PCM Source" DSP
	echo "setup klar: TDM_0 Four/S32, EP1+EP6 -> TDM_0_RX, Protection-fw + cal, PCM Source=DSP, amp AV"
	echo "kör nu som din användare:  sh $0 pw   och sedan  sudo sh $0 on"
}

pw() {
	pactl set-card-profile alsa_card.platform-sound-aoc output:stereo-fallback
	pactl set-default-sink alsa_output.platform-sound-aoc.stereo-fallback
	pactl info | grep -E 'Server Name|Default Sink'
	pactl list sinks short
}

status() {
	echo "PCM Source        L=$(g 'PCM Source')  R=$(g 'R PCM Source')"
	echo "DSP1 Firmware     L=$(g 'DSP1 Firmware')  Preload L=$(g 'DSP1 Preload Switch') R=$(g 'R DSP1 Preload Switch')"
	echo "Main AMP Enable   L=$(g 'Main AMP Enable Switch')  R=$(g 'R Main AMP Enable Switch')"
	echo "TDM_0_RX          Chan=$(g 'TDM_0_RX Chan') Format=$(g 'TDM_0_RX Format') EP1=$(g 'TDM_0_RX Mixer EP1') EP6=$(g 'TDM_0_RX Mixer EP6')"
	echo "CAL_R             L=$(g 'DSP1 Protection cd CAL_R')  R=$(g 'R DSP1 Protection cd CAL_R')"
	grep -A2 '"audio_output_control"' /sys/devices/platform/soc@0/19000000.aoc/services 2>/dev/null
}

case "$1" in
	setup)  setup ;;
	pw)     pw ;;
	on)     amp 1; echo "amp PÅ (off när klar)" ;;
	off)    amp 0; echo "amp AV" ;;
	raw)    s "PCM Source" ASP; s "R PCM Source" ASP; echo "PCM Source=ASP" ;;
	dsp)    s "PCM Source" DSP; s "R PCM Source" DSP; echo "PCM Source=DSP" ;;
	status) status ;;
	*)      sed -n '2,9p' "$0" ;;
esac
