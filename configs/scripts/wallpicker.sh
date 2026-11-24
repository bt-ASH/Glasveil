#!/usr/bin/env bash
# ── 壁纸选择器（rofi 竖条预览）──────────────────────────────────────────────
# 外观按 ~/Pictures/mockup-wallpaper-strips.md 的效果图：整屏深绿渐变 + 一排
# 231×816 的竖向长条（两侧出血），没有文字、没有搜索框。
# 主题：~/.config/rofi/wallpaper.rasi
#
# rofi 里竖条的宽度由图片自身比例决定（element-icon 只定高度），所以缩略图
# 必须裁成 231:816，否则一排竖条会被撑歪。
# 选片后按类型应用：图片走 awww，视频走 mpvpaper；再触发 matugen 刷新配色。
set -uo pipefail

WALLDIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpicker/v4"
THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/wallpaper.rasi"
STRIP_W=462        # 缩略图 = 2× 物理显示尺寸（rofi 里按 816 高渲染）
STRIP_H=1632
mkdir -p "$CACHE"

mapfile -t images < <(find "$WALLDIR" -maxdepth 2 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.avif' \
       -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \
       -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.avi' \
       -o -iname '*.flv' -o -iname '*.wmv' \) 2>/dev/null | sort)
[ "${#images[@]}" -eq 0 ] && { notify-send "Wallpaper" "目录里没有图片: $WALLDIR"; exit 1; }

# 1) 缩略图（存在则复用；文件名 + mtime 作为缓存键）
#    裁切 = 先按最短边铺满，再居中裁成 231:816 的竖向切片；直角、无描边，
#    和效果图里的竖条一致。
thumb_of() {
    local src="$1" base hash
    base="$(basename "${src%.*}")"
    hash="$(printf '%s:%s' "$src" "$(stat -c %Y "$src" 2>/dev/null || echo 0)" | md5sum | cut -c1-8)"
    printf '%s/%s-%s.jpg' "$CACHE" "$base" "$hash"
}

# 先按 231:816 的比例量出裁切框再缩放（比例与效果图的 960:3399 一致），
# 比整图缩放再裁快很多。
# 动图 webp（壁纸目录里有 3840×2160、几百 MB 的份）ImageMagick 会把所有帧
# 都解出来，慢到不可用，所以先用 ffmpeg 抠第一帧。
make_thumb() {
    local src="$1" out="$2" tmp="${2%.jpg}.tmp.jpg" dim w h cw ch x y frame=""
    case "${src,,}" in
        *.webp|*.mp4|*.webm|*.mkv|*.mov|*.m4v|*.avi|*.flv|*.wmv)
            if command -v ffmpeg >/dev/null 2>&1; then
                frame="${out%.jpg}.frame.png"
                ffmpeg -v error -i "$src" -frames:v 1 -y "$frame" 2>/dev/null || {
                    rm -f "$frame"; return 1; }
                src="$frame"
            fi ;;
    esac
    dim="$(magick identify -format "%w %h" "$src" 2>/dev/null)" || return 1
    w="${dim%% *}"; h="${dim##* }"
    [ -n "${w:-}" ] && [ -n "${h:-}" ] && [ "$w" -gt 0 ] && [ "$h" -gt 0 ] || { rm -f "$frame"; return 1; }
    if [ $(( w * STRIP_H )) -ge $(( h * STRIP_W )) ]; then
        cw=$(( (h * STRIP_W + STRIP_H / 2) / STRIP_H )); ch=$h      # 横图：裁窄
    else
        cw=$w; ch=$(( (w * STRIP_H + STRIP_W / 2) / STRIP_W ))      # 竖图：裁高
    fi
    x=$(( (w - cw) / 2 )); y=$(( (h - ch) / 2 ))
    magick "$src" -auto-orient -crop "${cw}x${ch}+${x}+${y}" +repage -strip \
        -resize "${STRIP_W}x${STRIP_H}" -quality 88 "$tmp" 2>/dev/null || { rm -f "$tmp" "$frame"; return 1; }
    rm -f "$frame"
    mv -f "$tmp" "$out"
}

export CACHE STRIP_W STRIP_H
export -f thumb_of make_thumb

if command -v magick >/dev/null 2>&1; then
    missing=0
    for img in "${images[@]}"; do
        [ -f "$(thumb_of "$img")" ] || missing=$((missing + 1))
    done
    [ "$missing" -gt 8 ] && notify-send -t 1500 "Wallpaper" "正在生成 ${missing} 张缩略图…"

    printf '%s\0' "${images[@]}" |
        xargs -0 -P 4 -I{} bash -c 't=$(thumb_of "$1"); [ -f "$t" ] || make_thumb "$1" "$t"' _ {}
fi

# 2) 当前壁纸 → 预选中（awww query 的输出里带图片路径）
preselect=()
# 视频壁纸在 mpvpaper 层，awww 仍显示上一张静态图
cur=""
mpid=$(pgrep -x mpvpaper | head -1 || true)
[ -n "$mpid" ] && cur=$(tr '\0' '\n' < "/proc/$mpid/cmdline" | tail -1)
[ -n "$cur" ] || cur="$(command -v awww >/dev/null 2>&1 && awww query 2>/dev/null |
       sed -n 's/.*currently displaying: image: //p' | head -1)"
if [ -n "${cur:-}" ]; then
    for i in "${!images[@]}"; do
        [ "${images[i]}" = "$cur" ] && { preselect=(-selected-row "$i"); break; }
    done
fi

# 3) rofi：图标 = 竖条缩略图，不显示文字
#    输入框被主题藏掉了（看不见，但打字仍然过滤）；-no-custom 保证回车选中的
#    一定是真壁纸而不是手打的字符串。Left/Right 在 rofi 里本来绑给
#    kb-row-left/kb-row-right，横向排列下正好在竖条之间移动，不用另绑。
selected="$(
    for img in "${images[@]}"; do
        t="$(thumb_of "$img")"
        [ -f "$t" ] || t="$img"
        printf '%s\0icon\x1f%s\n' "$img" "$t"
    done | rofi -dmenu -i -show-icons -no-custom -p "" \
        ${preselect[@]+"${preselect[@]}"} -theme "$THEME" 2>/dev/null
)"

# 4) 应用壁纸：视频 → mpvpaper，图片 → awww；然后异步刷新 matugen 配色
[ -n "${selected:-}" ] || exit 0
APPLY="$HOME/.config/scripts/wallpaper-apply.sh"
[ -x "$APPLY" ] || APPLY="$(dirname "$(readlink -f "$0")")/wallpaper-apply.sh"
if [ ! -x "$APPLY" ]; then
    notify-send -u critical "Wallpaper" "找不到 wallpaper-apply.sh"
    exit 1
fi
"$APPLY" "$selected" --transition-type any --transition-duration 1 \
    || { notify-send -u critical "Wallpaper" "应用失败: $selected"; exit 1; }

# 与 waypaper 完全一致的善后：同步 waypaper/config.ini 的 wallpaper，
# 再原样执行它的 post_command（matugen-update + tmux source-file …）
POST="$HOME/.config/scripts/wallpaper-post.sh"
[ -x "$POST" ] || POST="$(dirname "$(readlink -f "$0")")/wallpaper-post.sh"
[ -x "$POST" ] && "$POST" "$selected"
