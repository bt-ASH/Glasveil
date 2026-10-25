#!/usr/bin/env bash
# ~/.config/niri/scripts/theme-toggle.sh
# 在 dark / light 之间切换整套配色，并用 matugen 重新生成所有下游配置。
# 由 niri 的 Mod+Shift+N 调用。
set -uo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/matugen-strategy"
mkdir -p "$CACHE"
MODE_FILE="$CACHE/mode"
TYPE_FILE="$CACHE/type"
INDEX_FILE="$CACHE/current_index"
LOG="${XDG_RUNTIME_DIR:-/tmp}/niri-theme-toggle.log"

cur="$(cat "$MODE_FILE" 2>/dev/null || echo dark)"
if [ "$cur" = "dark" ]; then new="light"; else new="dark"; fi

# --- 当前壁纸（优先「聚焦输出」的壁纸，回退 waypaper 配置）---
WALL=""
if command -v awww >/dev/null 2>&1; then
    OUT="$(niri msg focused-output 2>/dev/null | head -n 1 | awk -F '[()]' '{print $2}')"
    if [ -n "${OUT:-}" ]; then
        WALL="$(awww query 2>/dev/null | grep "^: ${OUT}:" | awk -F 'image: ' '{print $2}' | xargs)"
    fi
    [ -f "${WALL:-/nonexistent}" ] || WALL="$(awww query 2>/dev/null | awk -F 'image: ' '/image: /{print $2; exit}' | xargs)"
fi
if [ ! -f "${WALL:-/nonexistent}" ]; then
    WALL="$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$HOME/.config/waypaper/config.ini" 2>/dev/null | head -1 | xargs)"
    WALL="${WALL/#\~/$HOME}"
fi

TYPE="$(cat "$TYPE_FILE" 2>/dev/null || echo scheme-content)"
IDX="$(cat "$INDEX_FILE" 2>/dev/null || echo 0)"

if [ ! -f "${WALL:-/nonexistent}" ]; then
    notify-send -u critical "Theme" "找不到当前壁纸，无法切换配色"
    exit 1
fi

# --- 1) 用 matugen 生成新模式的全部配色 ---
if ! matugen image "$WALL" -t "$TYPE" -m "$new" --source-color-index "$IDX" >>"$LOG" 2>&1; then
    notify-send -u critical "Theme" "matugen 生成 $new 配色失败（日志: $LOG）"
    exit 1
fi
printf '%s' "$new" > "$MODE_FILE"

# --- 2) GTK / 系统深浅色 ---
if [ "$new" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" 2>/dev/null || true
    prefer_dark=0
else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true
    prefer_dark=1
fi

for d in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    [ -d "$d" ] || continue
    f="$d/settings.ini"
    [ -f "$f" ] || continue
    sed -i -E "s/^gtk-theme-name=.*/gtk-theme-name=$([ "$new" = light ] && echo adw-gtk3 || echo adw-gtk3-dark)/" "$f"
    if grep -q '^gtk-application-prefer-dark-theme=' "$f"; then
        sed -i -E "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$prefer_dark/" "$f"
    else
        printf 'gtk-application-prefer-dark-theme=%s\n' "$prefer_dark" >>"$f"
    fi
done

# --- 3) 热重载各应用 ---
command -v niri >/dev/null 2>&1 && niri msg action load-config-file >/dev/null 2>&1 || true
pkill -SIGUSR1 -x kitty 2>/dev/null || true
busctl --user --auto-start=no call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 \
    ReloadAddonConfig s classicui >/dev/null 2>&1 || true
if command -v eww >/dev/null 2>&1 && eww ping >/dev/null 2>&1; then
    eww reload >/dev/null 2>&1 || true
fi

# --- 4) 提示 ---
if [ "$new" = "light" ]; then
    notify-send -t 2000 "Theme : Light" "配色已切换为亮色"
else
    notify-send -t 2000 "Theme : Dark" "配色已切换为暗色"
fi
exit 0
