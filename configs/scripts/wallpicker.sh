#!/usr/bin/env bash
# ── 壁纸选择器（rofi 网格 + 缩略图）──────────────────────────────────────────
# 外观与 waypaper 的网格对齐：3 列大缩略图、无文字、浅色卡片、选中项蓝色描边
# 主题：~/.config/rofi/wallpaper.rasi
# 选片后用 awww 应用，并触发 matugen 刷新配色。
set -uo pipefail

WALLDIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpicker/v2"
THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/wallpaper.rasi"
THUMB_PX=480
mkdir -p "$CACHE"

# 1) 生成缩略图（存在则复用；文件名 + mtime 作为缓存键）
thumb_of() {
    local src="$1" base hash
    base="$(basename "${src%.*}")"
    hash="$(printf '%s:%s' "$src" "$(stat -c %Y "$src" 2>/dev/null || echo 0)" | md5sum | cut -c1-8)"
    printf '%s/%s-%s.png' "$CACHE" "$base" "$hash"
}

mapfile -t images < <(find "$WALLDIR" -maxdepth 2 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.avif' \) 2>/dev/null | sort)
[ "${#images[@]}" -eq 0 ] && { notify-send "Wallpaper" "目录里没有图片: $WALLDIR"; exit 1; }

export CACHE THUMB_PX
# 首次运行要生成缩略图，给个提示（>8 张需要现生成时）
if command -v magick >/dev/null 2>&1; then
    missing=0
    for img in "${images[@]}"; do
        h=$(printf "%s:%s" "$img" "$(stat -c %Y "$img" 2>/dev/null || echo 0)" | md5sum | cut -c1-8)
        [ -f "$CACHE/$(basename "${img%.*}")-$h.png" ] || missing=$((missing + 1))
    done
    [ "$missing" -gt 8 ] && notify-send -t 1500 "Wallpaper" "正在生成 ${missing} 张缩略图…"
fi
if command -v magick >/dev/null 2>&1; then
    printf '%s\0' "${images[@]}" | xargs -0 -P 4 -I{} sh -c '
        src="$1"
        h=$(printf "%s:%s" "$src" "$(stat -c %Y "$src" 2>/dev/null || echo 0)" | md5sum | cut -c1-8)
        out="$CACHE/$(basename "${src%.*}")-$h.png"
        [ -f "$out" ] || magick "$src" -thumbnail "x$THUMB_PX" -strip "$out" 2>/dev/null || true
    ' _ {}
fi

# 2) rofi 网格（图标 = 缩略图，不显示文字）
selected="$(
    for img in "${images[@]}"; do
        t="$(thumb_of "$img")"
        [ -f "$t" ] || t="$img"
        printf '%s\0icon\x1f%s\n' "$img" "$t"
    done | rofi -dmenu -i -show-icons -p "" -theme "$THEME" 2>/dev/null
)"

# 3) 应用壁纸：统一走 awww，然后异步刷新 matugen 配色
[ -n "${selected:-}" ] || exit 0
if command -v awww >/dev/null 2>&1; then
    awww img "$selected" --transition-type any --transition-duration 1 2>/dev/null \
        || awww img "$selected"
else
    notify-send -u critical "Wallpaper" "找不到 awww"
    exit 1
fi

for updater in "$HOME/.local/bin/matugen-update" "$HOME/.config/scripts/matugen-update.sh"; do
    if [ -x "$updater" ]; then
        setsid "$updater" >/dev/null 2>&1 &
        break
    fi
done
