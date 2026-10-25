#!/usr/bin/env bash
# Orbit 菜单入口：在浮动终端里打开缓存清理 TUI
# 实际清理逻辑：~/.config/niri/scripts/clean-cache.py（独立版，不依赖 nyxuri 包）
exec kitty --app-id scratchpad --title "Glasveil · Cache Cleaner" -e "$HOME/.config/niri/scripts/clean-cache.py"
