#!/usr/bin/env bash
# ── 壁纸应用后的统一善后（对齐 waypaper 的行为）──────────────────────────────
# waypaper 选完壁纸后做两件事，rofi 选择器也必须照做，否则主题不会刷新、
# 下次开机还会被 restore-wallpaper.sh 恢复成旧图：
#
#   1. 把新壁纸写回 ~/.config/waypaper/config.ini 的 `wallpaper = ...`
#      （restore-wallpaper.sh 开机恢复、matugen-update 无参调用都读它）
#   2. 原样执行同一份 config.ini 里的 `post_command`
#      本机当前是：/home/ash/.local/bin/matugen-update && (tmux source-file ~/.tmux.conf …)
#
# 用法：wallpaper-post.sh /path/to/wallpaper
# 被 wallsel.sh（Mod+B 卡片选择器）与 wallpicker.sh（竖条选择器）调用。
set -u

WALL="${1:-}"
CONFIG="${WAYPAPER_CONFIG:-$HOME/.config/waypaper/config.ini}"

[ -n "$WALL" ] && [ -f "$WALL" ] || { printf '用法: %s /path/to/wallpaper\n' "$0" >&2; exit 1; }

# ── 1) 同步 waypaper 状态 ──────────────────────────────────────────────────
if [ -f "$CONFIG" ]; then
    esc=${WALL//\\/\\\\}      # sed 替换串转义：\ & |
    esc=${esc//&/\\&}
    esc=${esc//|/\\|}
    if grep -qE '^[[:space:]]*wallpaper[[:space:]]*=' "$CONFIG"; then
        sed -i "s|^[[:space:]]*wallpaper[[:space:]]*=.*|wallpaper = $esc|" "$CONFIG"
    else
        printf '\nwallpaper = %s\n' "$WALL" >> "$CONFIG"
    fi
fi

# ── 2) 跑 waypaper 的 post_command（原样、后台）────────────────────────────
cmd=""
if [ -f "$CONFIG" ]; then
    cmd=$(sed -n 's/^[[:space:]]*post_command[[:space:]]*=[[:space:]]*//p' "$CONFIG" | head -1)
fi
if [ -n "${cmd:-}" ]; then
    setsid bash -c "$cmd" >/dev/null 2>&1 &
    exit 0
fi

# ── 3) 兜底：没配 post_command 也至少刷新一次 matugen ─────────────────────
for updater in "$HOME/.local/bin/matugen-update" "$HOME/.config/scripts/matugen-update.sh"; do
    if [ -x "$updater" ]; then
        setsid "$updater" "$WALL" >/dev/null 2>&1 &
        exit 0
    fi
done
