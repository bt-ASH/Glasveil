#!/bin/bash
# 用 matugen 渲染色板替换 clipse 的 custom_theme.json

RENDERED="$HOME/.cache/matugen/clipse-theme.json"
TARGET="$HOME/.config/clipse/custom_theme.json"

[ -f "$RENDERED" ] || exit 0

cp "$TARGET" "$TARGET.bak"
cp "$RENDERED" "$TARGET"

# 重启 clipse daemon 使其加载新主题
# niri config 中已有 spawn-sh-at-startup "clipse --listen"，pkill 后它会自动重启
pkill -x clipse 2>/dev/null || true

exit 0
