#!/bin/bash
# 根据模式文件切换显示：默认时间 HH:MM，点击后显示年月日
MODE_FILE=/tmp/eww-clock-mode
if [ -f "$MODE_FILE" ]; then
    date '+%Y-%m-%d'
else
    date '+%H:%M'
fi
