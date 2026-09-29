#echo on |sudo tee /sys/bus/pci/devices/0001:00:00.0/power/control     # RC HSI2: ingen runtime-suspend
#echo on |sudo tee /sys/bus/pci/devices/0001:01:00.0/power/control     # wifi EP
# echo 0  |sudo tee /sys/bus/pci/devices/0001:01:00.0/link/l1_aspm
# echo performance |sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# sudo echo performance |sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# sudo pm.sh $2
