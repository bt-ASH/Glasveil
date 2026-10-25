#!/bin/bash
# wpctl volume -> percentage number (or "muted")
vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
if echo "$vol" | grep -q MUTED; then
  echo "muted"
else
  echo "$vol" | sed 's/Volume: //' | awk '{printf "%d", $1*100}'
fi
