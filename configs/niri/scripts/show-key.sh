#!/usr/bin/env bash
# 在屏幕上显示最近按下的键（从 stdin 读取）
# 需要: notify-send (libnotify)
KEY="$(cat /dev/stdin)"
notify-send -t 1500 "Key Pressed" "$KEY" 2>/dev/null
