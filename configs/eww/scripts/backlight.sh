#!/bin/bash
# backlight percentage from sysfs
dev=$(ls /sys/class/backlight/ | head -n1)
if [ -n "$dev" ]; then
  cur=$(cat /sys/class/backlight/$dev/brightness)
  max=$(cat /sys/class/backlight/$dev/max_brightness)
  echo $(( cur * 100 / max ))
else
  echo 0
fi
