#!/usr/bin/env bash
# ==============================================================================
# Glasveil 部署脚本
#   默认：逐文件软链到 ~/.config（改动即时生效，适合自用）
#   --copy：复制而不是链接（适合想脱离仓库单独维护）
#   --dry-run：只打印将要做什么
# 已存在的同名文件会先备份到 ~/.config/.glasveil-backup-<时间戳>/
# ==============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
MODE="link"
DRY=0

for arg in "$@"; do
    case "$arg" in
        --copy)    MODE="copy" ;;
        --link)    MODE="link" ;;
        --dry-run) DRY=1 ;;
        -h|--help)
            sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "未知参数: $arg" >&2; exit 1 ;;
    esac
done

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DEST/.glasveil-backup-$STAMP"
COUNT=0

deploy() {
    local src="$1" rel="$2" dst="$DEST/$2"
    if [ "$DRY" = 1 ]; then
        printf '  [%s] %s -> %s\n' "$MODE" "configs/$rel" "$dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        cp -a "$dst" "$BACKUP/$rel" 2>/dev/null || true
    fi
    if [ "$MODE" = "copy" ]; then
        cp -a "$src" "$dst"
    else
        ln -sfn "$src" "$dst"
    fi
    COUNT=$((COUNT + 1))
}

echo "Glasveil -> $DEST  (mode=$MODE)"

for dir in "$REPO"/configs/*/; do
    name="$(basename "$dir")"
    while IFS= read -r -d '' file; do
        deploy "$file" "${file#"$REPO"/configs/}"
    done < <(find "$dir" -type f ! -name '.module.toml' ! -path '*/__pycache__/*' -print0)
done

[ -f "$REPO/configs/starship.toml" ] && deploy "$REPO/configs/starship.toml" "starship.toml"

if [ "$DRY" = 0 ]; then
    [ -d "$BACKUP" ] && echo "旧文件已备份到 $BACKUP"
    echo "完成：部署了 $COUNT 个文件"
    echo
    echo "后续步骤："
    echo "  1. 首次生成配色：matugen image \"\$(awww query | awk -F 'image: ' '/image: /{print \$2; exit}')\" -t scheme-content -m dark"
    echo "  2. 重载 niri / eww：niri msg action load-config-file && eww reload"
    echo "  3. 电池保护（可选）：见 configs/niri/README-battery.md"
fi
