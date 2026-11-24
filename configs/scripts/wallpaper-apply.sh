#!/usr/bin/env bash
# ── 统一设置壁纸：视频走 mpvpaper，图片走 awww ───────────────────────────────
# 用法: wallpaper-apply.sh <壁纸路径> [传给 awww img 的额外参数...]
#
# 类型判断：`file --mime-type` 是 video/*，或扩展名属于常见视频格式。
# 视频：先 `awww kill` 结束静态壁纸 daemon，再用 mpvpaper 播放；
#       loop-file=inf 保证无限循环；panscan=1.0 让视频等比放大到铺满屏幕并裁掉
#       多余部分（与 awww 的填充一致）。
# 图片：反过来，先结束 mpvpaper，再拉起 awww-daemon 并 awww img。
set -u

WALL="${1:-}"
[ -n "$WALL" ] && [ -f "$WALL" ] || { printf '用法: %s <壁纸路径> [awww 参数...]\n' "$0" >&2; exit 1; }
shift || true

is_video() {
    local f="$1" mime
    mime=$(file -b --mime-type "$f" 2>/dev/null || true)
    case "$mime" in
        video/*) return 0 ;;
    esac
    case "${f,,}" in
        *.mp4|*.webm|*.mkv|*.mov|*.m4v|*.avi|*.flv|*.wmv|*.mpeg|*.mpg) return 0 ;;
    esac
    return 1
}

stop_mpvpaper() {
    pgrep -x mpvpaper >/dev/null 2>&1 || return 0
    pkill -x mpvpaper 2>/dev/null || true
    local i
    for i in $(seq 1 20); do
        pgrep -x mpvpaper >/dev/null 2>&1 || return 0
        sleep 0.05
    done
}

if is_video "$WALL"; then
    stop_mpvpaper
    command -v mpvpaper >/dev/null 2>&1 || { echo "找不到 mpvpaper" >&2; exit 1; }
    # 视频层与 awww 静态层互斥：先让 awww daemon 退出
    command -v awww >/dev/null 2>&1 && awww kill >/dev/null 2>&1 || true
    setsid mpvpaper -o "no-audio loop-file=inf panscan=1.0" "*" "$WALL" >/dev/null 2>&1 &
    exit 0
fi

stop_mpvpaper
command -v awww >/dev/null 2>&1 || { echo "找不到 awww" >&2; exit 1; }
pgrep -x awww-daemon >/dev/null 2>&1 || { awww-daemon >/dev/null 2>&1 & sleep 0.5; }

if [ "$#" -gt 0 ]; then
    awww img "$WALL" "$@" 2>/dev/null || awww img "$WALL"
else
    awww img "$WALL"
fi
