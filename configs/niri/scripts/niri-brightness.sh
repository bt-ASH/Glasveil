#!/usr/bin/env bash
# 亮度：内屏走 sysfs（brightnessctl），外接屏走 DDC/CI（ddcutil VCP 10）
#   niri-brightness.sh up|down [内屏步长%] [外屏步长]
# 说明：外接屏必须支持 DDC/CI；连接器 → ddcutil display 编号会缓存到
#       ~/.cache/niri-brightness.map，首次（或缓存失效）自动 ddcutil detect。
set -uo pipefail

dir="${1:-}"
step_pct="${2:-5}"
step_ddc="${3:-5}"
case "$dir" in
    up|down) ;;
    *) printf 'usage: niri-brightness.sh up|down [pct] [ddc-step]\n' >&2; exit 2 ;;
esac

apply_backlight() {
    command -v brightnessctl >/dev/null 2>&1 || return 1
    if [ "$dir" = up ]; then
        brightnessctl --class=backlight set "+${step_pct}%"
    else
        brightnessctl --class=backlight set "${step_pct}%-"
    fi
}

connector="$(niri msg focused-output 2>/dev/null | sed -n '1s/.*(\([^)]*\))$/\1/p')"

# 内屏（或拿不到连接器）直接走 sysfs
case "$connector" in
    eDP-*|LVDS-*|DSI-*|"")
        apply_backlight
        exit $?
        ;;
esac

map_file="${XDG_CACHE_HOME:-$HOME/.cache}/niri-brightness.map"
lookup_display() { [ -f "$map_file" ] && awk -v c="$1" '$1 == c { print $2; exit }' "$map_file"; }
refresh_map() {
    command -v ddcutil >/dev/null 2>&1 || return 1
    mkdir -p "$(dirname "$map_file")"
    ddcutil detect --brief 2>/dev/null | awk '
        /^Display [0-9]+$/  { d = $2 }
        /DRM connector:/    { c = $3; sub(/^card[0-9]+-/, "", c); if (c != "" && d != "") print c, d }
    ' > "$map_file" 2>/dev/null
    [ -s "$map_file" ]
}

if ! command -v ddcutil >/dev/null 2>&1; then
    apply_backlight
    exit $?
fi

disp="$(lookup_display "$connector")"
if [ -z "${disp:-}" ]; then
    refresh_map
    disp="$(lookup_display "$connector")"
fi

if [ -z "${disp:-}" ]; then
    # 外接屏不支持 DDC，退回内屏 sysfs
    apply_backlight
    exit $?
fi

if [ "$dir" = up ]; then
    exec ddcutil --display "$disp" setvcp 10 + "$step_ddc"
else
    exec ddcutil --display "$disp" setvcp 10 - "$step_ddc"
fi
