#!/bin/bash
# temperature in C
temp=$(sensors -u 2>/dev/null | awk '/temp1_input/ {print $2; exit}')
if [ -z "$temp" ]; then
  temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}')
fi
printf "%d" "${temp%.*}"
