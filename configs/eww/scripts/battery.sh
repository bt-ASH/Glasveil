#!/bin/bash
# battery percentage and status as JSON
dev=$(ls /sys/class/power_supply/ | grep -E '^BAT' | head -n1)
if [ -z "$dev" ]; then
  jq -n --arg cap "0" --arg status "Unknown" '{capacity:$cap, status:$status}'
  exit 0
fi
cap=$(cat /sys/class/power_supply/$dev/capacity 2>/dev/null || echo 0)
status=$(cat /sys/class/power_supply/$dev/status 2>/dev/null || echo "Unknown")
jq -n --arg cap "$cap" --arg status "$status" '{capacity:$cap, status:$status}'
