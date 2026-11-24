#!/usr/bin/env bash
# ── 把壁纸转换成 matugen 能读取的图片 ───────────────────────────────────────
# 用法: wallpaper-frame.sh <壁纸路径>
# 输出: 可直接喂给 `matugen image` 的图片路径
#   · 视频 / 动图 webp：用 ffmpeg 取首帧（缩到 500px），
#     缓存到 matugen-strategy/shrunk_images
#   · 图片：原样输出
set -u

WALL="${1:-}"
[ -n "$WALL" ] && [ -f "$WALL" ] || { printf '用法: %s <壁纸路径>\n' "$0" >&2; exit 1; }

mime=$(file -b --mime-type "$WALL" 2>/dev/null || true)
need_frame=false
case "$mime" in
    video/*|image/webp) need_frame=true ;;
esac
case "${WALL,,}" in
    *.mp4|*.webm|*.mkv|*.mov|*.m4v|*.avi|*.flv|*.wmv|*.mpeg|*.mpg|*.webp) need_frame=true ;;
esac

if [ "$need_frame" = false ]; then
    printf '%s\n' "$WALL"
    exit 0
fi

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/matugen-strategy/shrunk_images"
mkdir -p "$CACHE"
hash=$(printf '%s' "$WALL" | md5sum | awk '{print $1}')
out="$CACHE/$hash.png"

if [ ! -f "$out" ]; then
    if command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -v error -i "$WALL" -frames:v 1 \
            -vf "scale='min(500,iw)':-1" -y "$out" >/dev/null 2>&1
    fi
    # ffmpeg 不可用/失败时退回 ImageMagick，显式取 [0] 首帧
    if [ ! -f "$out" ] && command -v magick >/dev/null 2>&1; then
        magick "$WALL[0]" -resize 500x500\> "png:$out" >/dev/null 2>&1
    fi
    [ -f "$out" ] || { echo "取首帧失败: $WALL" >&2; exit 1; }
fi

printf '%s\n' "$out"
