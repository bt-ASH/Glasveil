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

    # 显卡选择：默认 auto —— 跟随 niri 实际使用的渲染节点。
    #   niri 在 N 卡（renderD129）→ mpvpaper 也用 N 卡，避免跨卡 dmabuf；
    #   niri 在核显（renderD128）→ mpvpaper 用核显 + VAAPI。
    # 也可强制：WALLPAPER_GPU=nvidia / intel。
    #
    # 注意：940MX 没有可用 NVDEC（ffmpeg 报 "Hardware is lacking required capabilities"），
    # 所以 N 卡模式下只能 CPU 解码；且 nvidia-580xx 的 PRIME 导入路径有 KFENCE UAF，
    # 跨卡时会出现花屏。只有 niri 也在 N 卡上时才建议用 nvidia。
    gpu_wrap=()
    mpv_dec="hwdec=vaapi"
    wall_gpu="${WALLPAPER_GPU:-auto}"
    if [ "$wall_gpu" = "auto" ]; then
        niri_pid=$(systemctl --user show -p MainPID --value niri 2>/dev/null || true)
        [ -n "$niri_pid" ] || niri_pid=$(pgrep -o -x niri 2>/dev/null || true)
        if [ -n "$niri_pid" ] && journalctl _PID="$niri_pid" -o cat 2>/dev/null |
            grep -q 'using as the render node: "/dev/dri/renderD129"'; then
            wall_gpu="nvidia"
        else
            wall_gpu="intel"
        fi
    fi
    if [ "$wall_gpu" = "nvidia" ] && command -v prime-run >/dev/null 2>&1; then
        gpu_wrap=(prime-run)
        mpv_dec=""
    fi
    setsid "${gpu_wrap[@]}" mpvpaper -o "no-audio loop-file=inf panscan=1.0${mpv_dec:+ $mpv_dec}" "*" "$WALL" >/dev/null 2>&1 &
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
