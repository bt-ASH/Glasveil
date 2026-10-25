#!/bin/bash
# 右键音量：静音/取消静音切换，立即刷新显示
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
eww update volume="$(/home/ash/.config/eww/scripts/volume.sh)"
