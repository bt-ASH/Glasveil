#!/bin/bash
# cycle power profile: balanced -> performance -> power-saver -> balanced
current=$(powerprofilesctl get 2>/dev/null || echo balanced)
case "$current" in
  performance) next="power-saver" ;;
  power-saver) next="balanced" ;;
  balanced)    next="performance" ;;
  *)           next="balanced" ;;
esac
powerprofilesctl set "$next"
# set 完成后立即读回实际状态刷新，不等 1s 轮询
eww update ppd="$(powerprofilesctl get 2>/dev/null || echo balanced)"
