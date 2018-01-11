#!/bin/bash

echo "---[e1000e driver info]---"
dmesg | grep "e1000e.*Intel.*PRO.*Network Driver" | tail -1

cat .modeinfo
