#!/bin/bash
case "$1" in
  up) wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%- ;;
esac
# 立即刷新显示，不等 1s 轮询
eww update volume="$(/home/ash/.config/eww/scripts/volume.sh)"
