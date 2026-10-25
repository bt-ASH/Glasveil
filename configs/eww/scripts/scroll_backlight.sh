#!/bin/bash
# eww onscroll -> up/down, 和 waybar backlight 滚轮行为一致
dir=$1
if [ "$dir" = "up" ]; then
    brightnessctl set +1%
else
    brightnessctl set 1%-
fi
# 立即刷新显示，不等 5s 轮询
eww update bl="$(/home/ash/.config/eww/scripts/backlight.sh)"
