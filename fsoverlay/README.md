# rootfs-overlay — allt som lades på enheten 2026-09-12 (ny rootfs)

    scp -r ~/pmbootstrap/rootfs-overlay simon@172.16.42.1:~/
    ssh simon@172.16.42.1 sudo sh ~/rootfs-overlay/install.sh
    reboot

## Innehåll och varför

lib/firmware/            aoc.bin, bcmdhd (fw/cal/clm/map), cirrus/ (cs35l41 wmfw/bin,
                         + -oriole-r.bin = o6Bottom for R-ampen), brcm/ (BT hcd),
                         google/edgetpu-abrolhos.fw, ftm5_fw_o6.ftb
etc/modprobe.d/trusty-order.conf   softdep trusty_virtio pre: trusty_ipc
etc/modprobe.d/aoc-trusty.conf     samma ordning + aoc_core options
                                   -> trusty_ipc MASTE laddas fore trusty_virtio, annars
                                      avvisar Trusty START (validate_descr status 1),
                                      ingen GO_ONLINE, hwmgr.aoc onabar, SPEECH_IN-krasch
etc/modprobe.d/blacklist-brcmfmac.conf   bcmdhd ska aga BCM4389
etc/NetworkManager/conf.d/99-gs101-wifi.conf   aware_nmi0/wlan1/radiotap0 omanagerade
                                   -> annars bcmdhd-oops i dhd_net2idx fran wpa_supplicant
                                      (flush_pmksa), rtnl hangt, systemet fryser
etc/pulse/default.pa.d/aoc-speaker.pa   Pulse-sink "Speaker" pa hw:0,5 (EP6),
                                   tsched=0 mmap=no 4x3840B  -> mmap=yes ger brus
etc/local.d/aoc-audio.start        kor ~/ljud/1-setup.sh vid boot innan sessionen
                                   -> Pulse ser inget kort om ingen TDM_0_RX Mixer EP ar pa
home/simon/ljud/*.sh               1-setup 2-pulse 3-on 4-off 5-nohibernate status
home/simon/speaker.cal             fabrikscal (persist /audio/speaker.cal)

## Efter boot
Speaker ska vara default sink. Om inte: sudo sh ~/ljud/1-setup.sh ; pulseaudio -k

## rtkit (Pulse utan RT smattrar via Pulse-sinken, direkt hw:0,5 ar rent)
    sudo apk add rtkit
    sudo rc-update add rtkit default && sudo rc-service rtkit start
    pulseaudio -k        # sink-tradarna far rt_priority via rtkit

## EP1 (hw:0,0) ar en FLOAT32-endpoint (vendor: 40 x 48 frames x 2ch x 4 byte float)
S16 dit = knapptyst. Anvand EP6 (hw:0,5, S16) for Pulse, eller format=float32le pa EP1.

## mesa — kor 26.1.6-r2 (G78-patch), INTE 26.3.0_git (smastorningar)
`pmbootstrap sideload mesa ...` tar nyaste i packages/ = 26.3.0_git. Installera r2 explicit:
    scp ~/pmbootstrap/rootfs-overlay/apk/*.apk simon@172.16.42.1:~/mesa_stage/
    cd ~/mesa_stage && sudo apk add --allow-untrusted mesa-26.1.6-r2.apk mesa-dri-gallium-26.1.6-r2.apk mesa-egl-26.1.6-r2.apk mesa-gbm-26.1.6-r2.apk mesa-gl-26.1.6-r2.apk mesa-gles-26.1.6-r2.apk mesa-vulkan-panfrost-26.1.6-r2.apk mesa-vulkan-swrast-26.1.6-r2.apk
    logga ut/in

## wifi-hang (bcmdhd "resumed on timeout" ~15 s/17 min efter association)
etc/local.d/wifi-noaspm.start        l1_aspm=0 pa 0001:01:00.0 (RC saknar L1-substates, EP gar i L1.2 och vaknar aldrig)
etc/NetworkManager/conf.d/98-wifi-nopowersave.conf   wifi.powersave=2
