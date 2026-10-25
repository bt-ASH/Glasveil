#!/usr/bin/env bash
# ==============================================================================
# Glasveil 部署脚本
#
#   部署
#     ./install.sh                 逐文件软链到 ~/.config（改动即时生效，适合自用）
#     ./install.sh --copy          复制而不是链接（想脱离仓库独立维护）
#     ./install.sh --dry-run       只打印将要做什么
#
#   备份 / 恢复（备份放在 ~/.config/.glasveil-backups/<时间戳>/）
#     ./install.sh --backup        备份当前 ~/.config 里本仓库管理的那些文件
#     ./install.sh --backup 标签   自定义备份标签
#     ./install.sh --list-backups  列出所有备份
#     ./install.sh --restore latest        回滚到最近一次备份
#     ./install.sh --restore <时间戳|路径>  回滚到指定备份
#
# 部署时被覆盖的旧文件也会自动进同一个备份目录，可随时 --restore 回滚。
# ==============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_ROOT="$DEST/.glasveil-backups"
MODE="link"
DRY=0
ACTION="deploy"
ARG=""

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$0"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --copy)          MODE="copy" ;;
        --link)          MODE="link" ;;
        --dry-run)       DRY=1 ;;
        --backup)        ACTION="backup";  [ $# -ge 2 ] && [ "${2:0:2}" != "--" ] && { ARG="$2"; shift; } ;;
        --restore)       ACTION="restore"; ARG="${2:-latest}"; [ $# -ge 2 ] && shift ;;
        --list-backups)  ACTION="list" ;;
        -h|--help)       usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# 本仓库管理的目标文件（相对 $DEST 的路径）
# ---------------------------------------------------------------------------
target_files() {
    local dir file
    for dir in "$REPO"/configs/*/; do
        while IFS= read -r -d '' file; do
            printf '%s\n' "${file#"$REPO"/configs/}"
        done < <(find "$dir" \( -type f -o -type l \) ! -name '.module.toml' ! -path '*/__pycache__/*' -print0)
    done
    [ -f "$REPO/configs/starship.toml" ] && printf '%s\n' "starship.toml"
    return 0
}


# 把 $1 复制到 $2：指向仓库的绝对软链会存成实体文件（真正的回滚），
# 相对软链（如 effects.kdl -> effects_normal.kdl）保持软链语义。
copy_entry() {
    if [ -L "$1" ]; then
        case "$(readlink "$1")" in
            /*) cp -aL "$1" "$2" ;;
            *)  cp -a  "$1" "$2" ;;
        esac
    else
        cp -a "$1" "$2"
    fi
}

# ---------------------------------------------------------------------------
# 备份：把 $DEST 里本仓库管理的现有文件收进一个带时间戳的目录
# ---------------------------------------------------------------------------
do_backup() {
    local tag="${1:-$(date +%Y%m%d-%H%M%S)}"
    local out="$BACKUP_ROOT/$tag" rel src n=0
    if [ -d "$out" ]; then out="$out-$(date +%H%M%S)"; fi

    while IFS= read -r rel; do
        src="$DEST/$rel"
        [ -e "$src" ] || [ -L "$src" ] || continue
        if [ "$DRY" = 1 ]; then
            printf '  [backup] %s\n' "$DEST/$rel"
            n=$((n + 1)); continue
        fi
        mkdir -p "$out/$(dirname "$rel")"
        if [ -L "$src" ]; then
            printf '%s\t%s\n' "$rel" "$(readlink "$src")" >> "$out/LINKS.tsv"
        fi
        copy_entry "$src" "$out/$rel"
        n=$((n + 1))
    done < <(target_files)

    if [ "$DRY" = 0 ]; then
        mkdir -p "$out"
        printf 'Glasveil backup\ncreated: %s\nfiles: %s\n' \
            "$(date '+%F %T')" "$n" > "$out/MANIFEST.txt"
        echo "已备份 $n 个文件 -> $out"
    else
        echo "(dry-run) 将备份 $n 个文件 -> $BACKUP_ROOT/$tag"
    fi
}

# ---------------------------------------------------------------------------
# 恢复：把备份目录里的文件写回 $DEST（先做一次安全备份）
# ---------------------------------------------------------------------------
do_restore() {
    local want="$1" src="" rel from to n=0
    if [ "$want" = "latest" ]; then
        src="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name 'pre-restore-*' 2>/dev/null | sort | tail -1)"
        [ -n "$src" ] || { echo "还没有任何备份（$BACKUP_ROOT 为空）" >&2; exit 1; }
    elif [ -d "$want" ]; then
        src="$want"
    elif [ -d "$BACKUP_ROOT/$want" ]; then
        src="$BACKUP_ROOT/$want"
    else
        echo "找不到备份: $want" >&2; echo "已存在的备份：" >&2; do_list; exit 1
    fi

    echo "将从备份恢复: $src"
    do_backup "pre-restore-$(date +%Y%m%d-%H%M%S)"

    while IFS= read -r rel; do
        case "$rel" in MANIFEST.txt|LINKS.tsv) continue ;; esac
        from="$src/$rel"; to="$DEST/$rel"
        if [ "$DRY" = 1 ]; then
            printf '  [restore] %s\n' "$to"; n=$((n + 1)); continue
        fi
        mkdir -p "$(dirname "$to")"
        rm -rf "$to"            # 清掉可能指向仓库的软链
        cp -a "$from" "$to"
        n=$((n + 1))
    done < <(cd "$src" && find . \( -type f -o -type l \) -print | sed 's|^\./||' | sort)

    # 还原软链（备份时记录的原始指向），使备份/恢复完全对称
    if [ -f "$src/LINKS.tsv" ] && [ "$DRY" = 0 ]; then
        while IFS=$'\t' read -r rel target; do
            [ -n "${rel:-}" ] || continue
            mkdir -p "$DEST/$(dirname "$rel")"
            ln -sfn "$target" "$DEST/$rel"
        done < "$src/LINKS.tsv"
        echo "已还原 $(wc -l < "$src/LINKS.tsv") 个软链"
    fi

    [ "$DRY" = 1 ] && echo "(dry-run) 将恢复 $n 个文件" || echo "已恢复 $n 个文件到 $DEST"
}

do_list() {
    if [ ! -d "$BACKUP_ROOT" ] || [ -z "$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ]; then
        echo "还没有任何备份（$BACKUP_ROOT）"
        return 0
    fi
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | while IFS= read -r tag; do
        dir="$BACKUP_ROOT/$tag"
        printf '  %-32s %4s 个文件   %s\n' "$tag" \
            "$(find "$dir" \( -type f -o -type l \) ! -name MANIFEST.txt ! -name LINKS.tsv | wc -l)" \
            "$(sed -n 's/^created: //p' "$dir/MANIFEST.txt" 2>/dev/null)"
    done
}

# ---------------------------------------------------------------------------
# 部署
# ---------------------------------------------------------------------------
do_deploy() {
    local stamp backup n=0 rel dst
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$BACKUP_ROOT/deploy-$stamp"

    echo "Glasveil -> $DEST  (mode=$MODE)"
    while IFS= read -r rel; do
        dst="$DEST/$rel"
        if [ "$DRY" = 1 ]; then
            printf '  [%s] configs/%s -> %s\n' "$MODE" "$rel" "$dst"
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mkdir -p "$backup/$(dirname "$rel")"
            copy_entry "$dst" "$backup/$rel" 2>/dev/null || true
        fi
        if [ "$MODE" = "copy" ]; then cp -a "$REPO/configs/$rel" "$dst"; else ln -sfn "$REPO/configs/$rel" "$dst"; fi
        n=$((n + 1))
    done < <(target_files)

    if [ "$DRY" = 0 ]; then
        mkdir -p "$backup"
        printf 'Glasveil deploy backup\ncreated: %s\nfiles: %s\nmode: %s\n' \
            "$(date '+%F %T')" "$n" "$MODE" > "$backup/MANIFEST.txt"
        echo "部署了 $n 个文件；被覆盖的旧文件已备份到 $backup"
        echo
        echo "后续步骤："
        echo "  1. 首次生成配色：matugen image \"\$(awww query | awk -F 'image: ' '/image: /{print \$2; exit}')\" -t scheme-content -m dark"
        echo "  2. 重载：niri msg action load-config-file && eww reload"
        echo "  3. 电池保护（可选）：见 configs/niri/README-battery.md"
    fi
}

case "$ACTION" in
    backup)  do_backup "${ARG:-}";;
    restore) do_restore "$ARG";;
    list)    do_list;;
    deploy)  do_deploy;;
esac
