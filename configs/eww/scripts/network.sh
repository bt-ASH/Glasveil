#!/bin/bash
# network display text (waybar style)
essid=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n1)
sig=$(nmcli -f in-use,signal dev wifi 2>/dev/null | grep '^\*' | awk '{print $2}')
if [ -n "$essid" ]; then
  if [ -n "$sig" ]; then
    echo "󰖩  ${essid} (${sig}%)"
  else
    echo "󰈀  Disconnected"
  fi
else
    echo "󰖪  ${essid}"
fi
