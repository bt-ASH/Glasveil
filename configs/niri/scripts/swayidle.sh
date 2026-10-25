#!/usr/bin/env bash

swayidle \
    timeout 300  'hyprlock -c ~/.config/niri/hyprlock.conf &' \
    timeout 600  'niri msg action power-off-monitors' \
    resume       'niri msg action power-on-monitors' \
    before-sleep 'hyprlock -c ~/.config/niri/hyprlock.conf || swaylock'
   # timeout 3700 'systemctl suspend'
