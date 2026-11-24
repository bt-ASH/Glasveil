#!/usr/bin/env bash
# ~/.config/niri/scripts/restore-wallpaper.sh
# 在 niri 启动时从 waypaper 配置读取壁纸并设置
# 需要在 awww-daemon 启动后执行

sleep 2  # 等待 awww-daemon 就绪

WALL=$(grep '^wallpaper ' ~/.config/waypaper/config.ini | head -1 | cut -d= -f2 | xargs)
WALL="${WALL/#\~/$HOME}"

if [ -n "$WALL" ] && [ -f "$WALL" ]; then
    # 图片 / 视频统一交给 wallpaper-apply.sh（视频用 mpvpaper）
    APPLY="$HOME/.config/scripts/wallpaper-apply.sh"
    [ -x "$APPLY" ] || APPLY="$(dirname "$(readlink -f "$0")")/../../scripts/wallpaper-apply.sh"
    if [ -x "$APPLY" ]; then
        "$APPLY" "$WALL"
    else
        awww img "$WALL"
    fi
fi
