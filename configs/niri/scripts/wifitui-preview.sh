#!/usr/bin/env bash
# 预览 wifitui 配色
#   wifitui-preview.sh               # 用 matugen 生成的主题开一个浮动终端
#   wifitui-preview.sh <theme.toml>  # 指定主题文件
#   wifitui-preview.sh --swatch      # 只在当前终端打印 10 个颜色的色块
#   wifitui-preview.sh --default     # 用 wifitui 自带默认主题开一个窗口（对比用）
set -uo pipefail

THEME_DEFAULT="$HOME/.config/wifitui/theme.toml"
arg="${1:-}"

if [ "$arg" = "--swatch" ]; then
    theme="${2:-$THEME_DEFAULT}"
    [ -f "$theme" ] || { echo "找不到主题文件: $theme" >&2; exit 1; }
    echo "主题文件: $theme"
    while IFS='=' read -r key value; do
        key="$(printf '%s' "$key" | xargs)"
        value="$(printf '%s' "$value" | sed -E 's/[[:space:]]+#.*$//' | tr -d ' ",' | xargs)"
        [ -n "$key" ] || continue
        case "$key" in
            Primary|Subtle|Success|Error|Normal|Disabled|Border|SignalHigh|SignalLow|Saved) ;;
            *) continue ;;
        esac
        hex="${value#\#}"
        [ ${#hex} -eq 6 ] || continue
        printf '  %-11s #%s  \033[48;2;%d;%d;%dm        \033[0m\n' \
            "$key" "$hex" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
    done < "$theme"
    exit 0
fi

if [ "$arg" = "--default" ]; then
    exec kitty --class wifitui --title "wifitui (default theme)" -e wifitui tui
fi

theme="${arg:-$THEME_DEFAULT}"
[ -f "$theme" ] || { echo "找不到主题文件: $theme（先跑一次 matugen 生成）" >&2; exit 1; }
exec kitty --class wifitui --title "wifitui · $(basename "$theme")" -e wifitui --theme "$theme" tui
