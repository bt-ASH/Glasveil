#!/usr/bin/env bash
# ── 壁纸选择器：rofi 单行竖版卡片 + 文件名标签 ───────────────────────────────
# 源自 hyprdots 的 wallsel-v2.sh，按本机 niri / Glasveil 环境改写：
#   · 屏幕宽度改用 niri IPC（focused-output），不再依赖 hyprctl
#   · 壁纸目录默认 ~/Pictures/Wallpapers（WALL_DIR / WALLPAPER_DIR 可覆盖）
#   · 应用壁纸统一走 awww（含 daemon 自启），选完按 waypaper 的
#     post_command 善后（写回 waypaper 状态 + matugen + tmux 重载）
#   · 配色交给 rofi 主题 wallsel.rasi（@import colors.rasi，跟随 Material You）
#   · 大体积动图 webp 先用 ffmpeg 抠首帧，避免 ImageMagick 解全部帧卡死
#
# niri 键位：Mod+B（configs/niri/__custom__.kdl）
# 依赖：rofi imagemagick jq awww（ffmpeg 可选，动图 webp 用）
set -u

# ── 外观 / Look（都可用环境变量覆盖）────────────────────────────────────────
COLUMNS_N="${WALLSEL_COLUMNS:-6}"          # 一屏卡片数
GAP="${WALLSEL_GAP:-40}"                   # 卡片间距
BAR_PAD_X="${WALLSEL_BAR_PAD_X:-40}"       # 横带左右内边距
BAR_PAD_Y="${WALLSEL_BAR_PAD_Y:-32}"       # 横带上下内边距
CARD_RATIO="${WALLSEL_CARD_RATIO:-150}"    # 卡片高 = 宽 × 150%（竖版）
CARD_RADIUS="${WALLSEL_CARD_RADIUS:-24}"   # 卡片圆角
CARD_PAD="${WALLSEL_CARD_PAD:-8}"          # 卡片与选中底色之间的内边距
SCREEN_W="${WALLSEL_SCREEN_W:-}"           # 自动探测失败时可手动指定
LABEL_PAD="${WALLSEL_LABEL_PAD:-14}"       # 文件名下方留白
LABEL_NOEXT="${WALLSEL_LABEL_NOEXT:-1}"    # 1 = 隐藏扩展名
LABEL_UPPER="${WALLSEL_LABEL_UPPER:-0}"    # 1 = 文件名转大写

WALL_DIR="${WALL_DIR:-${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallsel"
CURRENT_LINK="$CACHE_DIR/current"
THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/wallsel.rasi"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a Wallpaper "壁纸" "$1"; }
die()    { notify "$1"; printf '%s\n' "$1" >&2; exit 1; }

# ── 屏幕逻辑宽度 / logical screen width ────────────────────────────────────
detect_screen_w() {
    command -v niri >/dev/null 2>&1 || return 1
    command -v jq   >/dev/null 2>&1 || return 1
    niri msg -j focused-output 2>/dev/null |
        jq -r 'if .logical then .logical.width else empty end' 2>/dev/null
}
[ -z "$SCREEN_W" ] && SCREEN_W="$(detect_screen_w)"
[ -z "$SCREEN_W" ] && SCREEN_W=1920

command -v rofi   >/dev/null 2>&1 || die "需要 rofi"
command -v magick >/dev/null 2>&1 || die "需要 imagemagick（magick）"
[ -r "$THEME" ] || die "找不到主题: $THEME"

# ── 卡片 / 缩略图尺寸 ──────────────────────────────────────────────────────
COL_W=$(((SCREEN_W - 2 * BAR_PAD_X - (COLUMNS_N - 1) * GAP) / COLUMNS_N))
CARD_W=$((COL_W - 2 * CARD_PAD))
[ "$CARD_W" -lt 80 ] && CARD_W=80
CARD_H=$((CARD_W * CARD_RATIO / 100))

# 缩略图按 2× 渲染，rofi 缩放后仍然清晰
THUMB_W=$((CARD_W * 2))
THUMB_H=$((CARD_H * 2))
THUMB_R=$((CARD_RADIUS * 2))
THUMB_DIR="$CACHE_DIR/thumbs-${THUMB_W}x${THUMB_H}-r${THUMB_R}"
mkdir -p "$THUMB_DIR"

# ── 收集壁纸 / collect wallpapers ──────────────────────────────────────────
mapfile -d '' walls < <(
    find -L "$WALL_DIR" -maxdepth 3 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.avif' \
           -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \
           -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.avi' \
           -o -iname '*.flv' -o -iname '*.wmv' \) \
        -print0 2>/dev/null | sort -z
)
[ "${#walls[@]}" -gt 0 ] || die "目录里没有图片: $WALL_DIR"

# ── 缩略图缓存 / thumbnail cache ───────────────────────────────────────────
thumb_for() {
    local key
    key=$(printf '%s:%s:%s' "$1" "$(stat -c %Y "$1")" "$THUMB_R" | md5sum | cut -d' ' -f1)
    printf '%s/%s.png' "$THUMB_DIR" "$key"
}

# 竖版居中裁切 + 四角圆角；动图先抠首帧（几百 MB 的 webp 用 magick 会卡死）
make_thumb() {
    local wall="$1" out="$2" src="$1" frame=""
    [ -e "$out" ] && return 0
    case "${src,,}" in
        *.webp|*.gif|*.mp4|*.webm|*.mkv|*.mov|*.m4v|*.avi|*.flv|*.wmv)
            if command -v ffmpeg >/dev/null 2>&1; then
                frame="$out.frame.png"
                if ffmpeg -v error -i "$src" -frames:v 1 -y "$frame" 2>/dev/null; then
                    src="$frame"
                else
                    rm -f "$frame"; frame=""
                fi
            fi ;;
    esac
    timeout 60 magick "$src[0]" -strip \
        -thumbnail "${THUMB_W}x${THUMB_H}^" -gravity center \
        -extent "${THUMB_W}x${THUMB_H}" -alpha set \
        \( -size "${THUMB_W}x${THUMB_H}" xc:none -fill white \
           -draw "roundrectangle 0,0 $((THUMB_W - 1)),$((THUMB_H - 1)) $THUMB_R,$THUMB_R" \) \
        -compose DstIn -composite "png:$out.tmp" 2>/dev/null &&
        mv -f "$out.tmp" "$out"
    rm -f "$frame"
}
export THUMB_W THUMB_H THUMB_R
export -f make_thumb

pairs=()
for w in "${walls[@]}"; do
    t="$(thumb_for "$w")"
    if [ ! -e "$t" ]; then
        pairs+=("$w" "$t")
    fi
done
missing=$(( ${#pairs[@]} / 2 ))
[ "$missing" -gt 4 ] && notify "正在生成 ${missing} 张缩略图…"

if [ "${#pairs[@]}" -gt 0 ]; then
    printf '%s\0' "${pairs[@]}" |
        xargs -0 -n2 -P 4 bash -c 'make_thumb "$1" "$2"' _
fi

# ── 当前壁纸 → 预选中 / preselect current wallpaper ────────────────────────
cur_index=0
cur=""
# 视频壁纸在 mpvpaper 层，awww 还停留在上一张静态图，所以优先从 mpvpaper 进程取
mpid=$(pgrep -x mpvpaper | head -1 || true)
[ -n "$mpid" ] && cur=$(tr '\0' '\n' < "/proc/$mpid/cmdline" | tail -1)
if [ -z "$cur" ] && command -v awww >/dev/null 2>&1; then
    cur=$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)
fi
[ -n "$cur" ] || { [ -L "$CURRENT_LINK" ] && cur=$(readlink -f "$CURRENT_LINK"); }
if [ -n "$cur" ]; then
    cur_real=$(readlink -f "$cur")
    for i in "${!walls[@]}"; do
        if [ "$(readlink -f "${walls[i]}")" = "$cur_real" ]; then
            cur_index=$i
            break
        fi
    done
fi

# ── rofi：几何尺寸走 -theme-str，颜色/字体在 wallsel.rasi ──────────────────
geo="
window { padding: ${BAR_PAD_Y}px ${BAR_PAD_X}px; }
listview { columns: ${COLUMNS_N}; spacing: ${GAP}px; }
element { padding: ${CARD_PAD}px ${CARD_PAD}px ${LABEL_PAD}px ${CARD_PAD}px; }
element-icon { size: ${CARD_H}px; }
"

# vim 式选择：卡片只有一行，所以 h/l 与 j/k 都按“上一张 / 下一张”线性走；
# ↑/↓ 保持 rofi 默认的前后换卡（←/→ 已被 rofi 占用，不能重复绑定）。
# 注意：dmenu 里字母键被吃掉后就不能再用 h/j/k/l 过滤文件名
nav=(
    -kb-row-up   "Up,Control+p,k,h"
    -kb-row-down "Down,Control+n,j,l"
)

label_for() {
    local n
    n=$(basename "$1")
    [ "$LABEL_NOEXT" = 1 ] && n="${n%.*}"
    [ "$LABEL_UPPER" = 1 ] && n="${n^^}"
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.mov|*.m4v|*.avi|*.flv|*.wmv) n="▶ $n" ;;
    esac
    printf '%s' "$n"
}

choice=$(
    for w in "${walls[@]}"; do
        printf '%s\0icon\x1f%s\n' "$(label_for "$w")" "$(thumb_for "$w")"
    done | rofi -dmenu -i -show-icons -format i -p "" \
        -selected-row "$cur_index" "${nav[@]}" \
        -theme "$THEME" -theme-str "$geo" 2>/dev/null
)
[ -n "${choice:-}" ] || exit 0
selected="${walls[$choice]:-}"
[ -n "$selected" ] || exit 0

ln -sfn "$selected" "$CURRENT_LINK"

# ── 应用壁纸 / apply wallpaper（视频 → mpvpaper，图片 → awww）───────────────
APPLY="$HOME/.config/scripts/wallpaper-apply.sh"
[ -x "$APPLY" ] || APPLY="$(dirname "$(readlink -f "$0")")/../scripts/wallpaper-apply.sh"
[ -x "$APPLY" ] || die "找不到 wallpaper-apply.sh"
"$APPLY" "$selected" --transition-type any --transition-duration 1 || die "应用壁纸失败: $selected"

# 与 waypaper 完全一致的善后：同步 waypaper/config.ini 的 wallpaper，
# 再原样执行它的 post_command（matugen-update + tmux source-file …）
POST="$HOME/.config/scripts/wallpaper-post.sh"
[ -x "$POST" ] || POST="$(dirname "$(readlink -f "$0")")/../scripts/wallpaper-post.sh"
[ -x "$POST" ] && "$POST" "$selected"
