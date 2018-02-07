#!/bin/bash

NON_PATCHED_E1000E="ext-drivers/e1000e-3.3.6/src/e1000e.ko"
PATCHED_E1000E="e1000e/e1000e.ko"

RELOAD_E1000E=1
usage()
{
	echo "Usage $0: <interface> <emulated/patched>"
    exit 1
}

load_e1000e()
{
    ko=$PATCHED_E1000E
    [[ "$1" ==  "emulated" ]] && ko=$NON_PATCHED_E1000E
    echo "Loading $ko"
    insmod $ko
}

[[ "$2" == "" ]] && usage
[[ "$2" != "emulated" ]] && [[ "$2" != "patched" ]] && usage
echo "$2" > .modeinfo
ifconfig $1 > /dev/null
[[ $? -ne 0 ]] && echo "$1 interface not found" && usage
INTF="$1"

[[ $RELOAD_E1000E -eq 1 ]] && rmmod e1000e 2> /dev/null
lsmod | grep netmap > /dev/null
[[ $? -eq 0 ]] && rmmod netmap

insmod netmap.ko
[[ $RELOAD_E1000E -eq 1 ]] && load_e1000e "$2"

service lightdm stop
./hyperthreading_ctl.sh disable_all
#./hyperthreading_ctl.sh enable_all
#./hyperthreading_ctl.sh disable_ht
ethtool -K $INTF tx off rx off gso off tso off gro off lro off
echo "$2" > .modeinfo
