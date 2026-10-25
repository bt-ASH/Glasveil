#!/usr/bin/env bash
# 音量：优先 swayosd（带 OSD），否则 wpctl 静默调节
#   niri-volume.sh up|down|mute [步长%]
set -uo pipefail

action="${1:-}"
step="${2:-5}"
case "$action" in
    up|down|mute) ;;
    *) printf 'usage: niri-volume.sh up|down|mute [step%%]\n' >&2; exit 2 ;;
esac

# swayosd 需要常驻 swayosd-server，没跑就退回 wpctl
if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null 2>&1; then
    case "$action" in
        up)   exec swayosd-client --output-volume raise ;;
        down) exec swayosd-client --output-volume lower ;;
        mute) exec swayosd-client --output-volume mute-toggle ;;
    esac
fi

if ! command -v wpctl >/dev/null 2>&1; then
    command -v pactl >/dev/null 2>&1 || exit 1
    case "$action" in
        up)   exec pactl set-sink-volume @DEFAULT_SINK@ "+${step}%" ;;
        down) exec pactl set-sink-volume @DEFAULT_SINK@ "-${step}%" ;;
        mute) exec pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    esac
fi

case "$action" in
    up)   exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${step}%+" ;;
    down) exec wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%-" ;;
    mute) exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac
