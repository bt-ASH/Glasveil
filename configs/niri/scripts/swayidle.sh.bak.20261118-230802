#!/usr/bin/env bash

pgrep -x swayidle >/dev/null && exit 0

exec swayidle \
    timeout 300  'pgrep -x hyprlock >/dev/null || hyprlock -c ~/.config/niri/hyprlock.conf' \
    timeout 600  'niri msg action power-off-monitors' \
    resume       'niri msg action power-on-monitors' \
    before-sleep 'setsid -f hyprlock -c ~/.config/niri/hyprlock.conf' \
    timeout 3700 'systemctl suspend'
