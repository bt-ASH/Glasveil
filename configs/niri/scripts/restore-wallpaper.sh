#!/usr/bin/env bash
# ~/.config/niri/scripts/restore-wallpaper.sh
# 在 niri 启动时从 waypaper 配置读取壁纸并设置
# 需要在 awww-daemon 启动后执行

sleep 2  # 等待 awww-daemon 就绪

WALL=$(grep '^wallpaper ' ~/.config/waypaper/config.ini | head -1 | cut -d= -f2 | xargs)
WALL="${WALL/#\~/$HOME}"

if [ -n "$WALL" ] && [ -f "$WALL" ]; then
    awww img "$WALL"
fi
