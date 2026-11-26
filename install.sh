#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════╗
# ║               Glasveil Installer                   ║
# ║          niri / Material You / eww / matugen          ║
# ╚═══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Colors ──────────────────────────────────────────────
CRED='\033[1;31m'
CGRN='\033[1;32m'
CYLW='\033[1;33m'
CBLU='\033[1;34m'
CBLD='\033[1m'
CDIM='\033[2m'
CDEF='\033[0m'

# ── Paths ───────────────────────────────────────────────
# 跟随软链解析脚本真实位置：本脚本会软链到 ~/.local/bin/glasveil，
# 从那里调用时 dirname 会变成 ~/.local/bin，不能直接拿来当 REPO。
SELF="${BASH_SOURCE[0]}"
while [ -L "$SELF" ]; do
    _link="$(readlink "$SELF")"
    case "$_link" in
        /*) SELF="$_link" ;;
        *)  SELF="$(dirname "$SELF")/$_link" ;;
    esac
done
REPO="$(cd "$(dirname "$SELF")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_DEST="${XDG_BIN_HOME:-$HOME/.local/bin}"
BACKUP_ROOT="$DEST/.glasveil-backups"
FALLBACK_VERSION="1.3"   # 没有 git tag 时的兜底版本；正常情况由 git tag 决定

# 版本号来源：git 标签（单一事实来源）
#   v1.3            → 1.3
#   v1.3+5-g1a2b3c  → 1.3+5（tag 之后有 5 个提交）
#   v1.3+5-dirty    → 工作区有未提交改动
repo_version() {
    local base ahead dirty=""
    if command -v git >/dev/null 2>&1 && [ -d "$REPO/.git" ]; then
        # 取「当前提交可达的、版本号最大」的 tag（同一提交上打多个 tag 时也更确定）
        base="$(git -C "$REPO" tag --sort=-v:refname --merged HEAD 2>/dev/null | head -1)"
        if [ -n "$base" ]; then
            ahead="$(git -C "$REPO" rev-list --count "${base}..HEAD" 2>/dev/null || echo 0)"
            git -C "$REPO" diff --quiet 2>/dev/null || dirty="-dirty"
            if [ "${ahead:-0}" -gt 0 ]; then
                printf '%s+%s%s' "${base#v}" "$ahead" "$dirty"
            else
                printf '%s%s' "${base#v}" "$dirty"
            fi
            return
        fi
    fi
    printf '%s' "$FALLBACK_VERSION"
}
VERSION="$(repo_version)"

# 标题方框（55 列，ASCII 居中）
box_line() {
    local t="$1" pad left right
    pad=$((55 - ${#t})); left=$((pad / 2)); right=$((pad - left))
    printf '║%*s%s%*s║\n' "$left" '' "$t" "$right" ''
}

# ── Defaults (可由命令行覆盖) ────────────────────────────
MODE="link"      # link | copy
DRY=0            # 1 = 只打印，不落地
ASSUME_YES=0     # 1 = 跳过确认

# ── Package Lists ───────────────────────────────────────
# 仓库包：桌面运行所需（niri 本身、终端、取色、输入法、截图、音频亮度等）
REPO_PKGS=(
    niri kitty fish
    matugen starship yazi
    eww wifitui
    fcitx5 fcitx5-gtk fcitx5-configtool
    rofi mako
    hyprlock swayidle swaylock
    wl-clipboard grim slurp satty
    brightnessctl playerctl
    imagemagick
    awww wlsunset power-profiles-daemon
    networkmanager upower
    tmux libnotify jq
    python-gobject python-cairo gtk3 gtk-layer-shell
)

# AUR 包：需要 paru / yay
AUR_PKGS=(
    eww
    wifitui
    waypaper
    clipse
    wshowkeys
    mpvpaper
)

# 可选工具（仅提示，不强制安装）
OPTIONAL_PKGS=(btop cava bat eza zoxide fastfetch)

# ── Helpers ─────────────────────────────────────────────
info()  { printf "${CBLU}>>${CDEF} %s\n" "$*"; }
ok()    { printf "${CGRN}>>${CDEF} %s\n" "$*"; }
skip()  { printf "  ${CDIM}·${CDEF} %s\n" "$*"; }
warn()  { printf "${CYLW}>>${CDEF} %s\n" "$*" >&2; }
die()   { printf "${CRED}>>${CDEF} %s\n" "$*" >&2; exit 1; }
rule()  { printf "  ${CDIM}───────────────────────────────────────────────────${CDEF}\n"; }

# 需要确认的操作（--yes 可跳过）
confirm() {
    [ "$ASSUME_YES" = 1 ] && return 0
    [ "$DRY" = 1 ] && return 0
    local reply
    printf "%s " "$1 [y/N]"
    read -r reply
    case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# ── Self Link ───────────────────────────────────────────
# 把本脚本软链为 ~/.local/bin/glasveil，之后可直接 `glasveil deploy`。
# 必须用软链：复制到 bin 后 dirname 变了，脚本会找不到 configs/。
ensure_self_link() {
    [ "$DRY" = 1 ] && return 0
    local src="$REPO/install.sh" dst="$BIN_DEST/glasveil" bak
    [ -f "$src" ] || return 0
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        return 0
    fi
    # 同名实体文件不静默覆盖，先备份
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        bak="$BACKUP_ROOT/selflink-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$bak" && cp -a "$dst" "$bak/glasveil" || true
        skip "已备份同名文件 $dst -> $bak/glasveil"
    fi
    mkdir -p "$BIN_DEST" 2>/dev/null || return 0
    ln -sfn "$src" "$dst" 2>/dev/null || { warn "无法创建软链 $dst"; return 0; }
    ok "已链接命令: $dst -> $src"
}

# ── Managed Files ───────────────────────────────────────
# 本仓库管理哪些目标文件（相对 $DEST）：含软链（effects.kdl / current-theme.conf）
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

# 需要额外部署到 ${XDG_BIN_HOME:-~/.local/bin} 的命令：
#   输出「源文件绝对路径 <TAB> 命令名」
# 约定：命令的源码统一放 configs/scripts/，这里登记它到 ~/.local/bin 的映射；
# 仓库根 bin/ 下的文件也会被一并部署（兼容旧布局）。
local_bin_targets() {
    local file
    [ -f "$REPO/configs/scripts/matugen-update.sh" ] &&
        printf '%s\t%s\n' "$REPO/configs/scripts/matugen-update.sh" "matugen-update"
    if [ -d "$REPO/bin" ]; then
        while IFS= read -r -d '' file; do
            printf '%s\t%s\n' "$file" "${file##*/}"
        done < <(find "$REPO/bin" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -print0)
    fi
    return 0
}

# 把 $1 复制到 $2：指向仓库的绝对软链存实体内容（真回滚），相对软链保持链接
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

# ── Usage ───────────────────────────────────────────────
usage() {
    printf '╔═══════════════════════════════════════════════════════╗\n'
    box_line "Glasveil Installer v$VERSION"
    box_line "niri / Material You / eww / matugen"
    printf '╚═══════════════════════════════════════════════════════╝\n'
    cat <<'USAGE'

  (无参数)                      交互菜单（部署 / 依赖 / 备份 / 回滚）
  deploy                        只部署配置到 ~/.config（scripts 登记命令 → ~/.local/bin，默认命令）
  deps                          只安装依赖（仓库包 + AUR 包）
  all                           先装依赖再部署
  backup [标签]                 备份 ~/.config 与 ~/.local/bin 里本仓库管理的文件
  restore <引用>                回滚（latest / 备份标签 / 目录路径）
  list-backups                  列出已有备份
  version                       打印版本号（取自 git tag）

  --copy                        部署时复制而不是软链
  --link                        部署时软链（默认）
  --dry-run                     只打印将要做什么，不落地
  --yes, -y                     跳过所有确认
  --repo-only                   只装仓库包，跳过 AUR
  -h, --help                    显示本帮助

  首次运行会把本脚本软链到 ${XDG_BIN_HOME:-~/.local/bin}/glasveil，
  之后可直接用 `glasveil deploy` / `glasveil backup`，不必写仓库路径。

  示例
  ./install.sh                  交互菜单
  ./install.sh deps             只装依赖
  ./install.sh deploy --copy    只部署配置（复制模式）
  ./install.sh backup 调参前    打快照
  ./install.sh restore latest   回滚到最近一次


USAGE
}

show_menu() {
    printf "\n${CBLD}${CYLW}"
    echo "╔═══════════════════════════════════════════════════════╗"
    box_line "Glasveil Installer v$VERSION"
    box_line "niri / Material You / eww / matugen"
    echo "╚═══════════════════════════════════════════════════════╝"
    printf "${CDEF}\n"
    printf "  ${CBLD}可用操作:${CDEF}\n"
    rule
    printf "  ${CGRN}1)${CDEF}  只部署配置  ${CDIM}(deploy)${CDEF}\n"
    printf "  ${CGRN}2)${CDEF}  只安装依赖  ${CDIM}(deps)${CDEF}\n"
    printf "  ${CGRN}3)${CDEF}  依赖 + 配置 ${CDIM}(all)${CDEF}\n"
    printf "  ${CGRN}4)${CDEF}  备份当前配置 ${CDIM}(backup)${CDEF}\n"
    printf "  ${CGRN}5)${CDEF}  回滚最近备份 ${CDIM}(restore latest)${CDEF}\n"
    printf "  ${CGRN}6)${CDEF}  列出备份      ${CDIM}(list-backups)${CDEF}\n"
    rule
    printf "  ${CRED}q)${CDEF}  退出\n\n"
}

# ── Dependencies ────────────────────────────────────────
aur_helper() {
    command -v paru >/dev/null 2>&1 && { echo paru; return; }
    command -v yay  >/dev/null 2>&1 && { echo yay;  return; }
    echo ""
}

is_installed() { pacman -Qq "$1" >/dev/null 2>&1; }

cmd_deps() {
    local repo_only="$1"
    printf "\n${CBLD}>> 安装依赖${CDEF}\n"
    rule

    command -v pacman >/dev/null 2>&1 || die "只支持 Arch 系（未找到 pacman）"

    # ── 仓库包 ──
    local -a missing=()
    local p
    for p in "${REPO_PKGS[@]}"; do
        if is_installed "$p"; then skip "$p 已安装"; else missing+=("$p"); fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "仓库包已齐"
    else
        printf "  将安装仓库包: ${CGRN}%s${CDEF}\n" "${missing[*]}"
        if [ "$DRY" = 1 ]; then
            info "(dry-run) sudo pacman -S --needed ${missing[*]}"
        elif confirm "确认安装仓库包？"; then
            sudo pacman -S --needed --noconfirm "${missing[@]}"
        else
            warn "已跳过仓库包"
        fi
    fi

    # ── AUR 包 ──
    [ "$repo_only" = 1 ] && { warn "已按 --repo-only 跳过 AUR 包"; return 0; }

    local -a aur_missing=()
    for p in "${AUR_PKGS[@]}"; do
        if is_installed "$p"; then skip "$p 已安装"; else aur_missing+=("$p"); fi
    done

    if [ ${#aur_missing[@]} -eq 0 ]; then
        ok "AUR 包已齐"
    else
        local helper; helper="$(aur_helper)"
        printf "  将安装 AUR 包: ${CGRN}%s${CDEF}\n" "${aur_missing[*]}"
        if [ -z "$helper" ]; then
            warn "未找到 paru / yay，AUR 包需手动安装："
            printf "      ${CDIM}%s${CDEF}\n" "${aur_missing[*]}"
        elif [ "$DRY" = 1 ]; then
            info "(dry-run) $helper -S --needed ${aur_missing[*]}"
        elif confirm "用 $helper 安装 AUR 包？"; then
            "$helper" -S --needed --noconfirm "${aur_missing[@]}"
        else
            warn "已跳过 AUR 包"
        fi
    fi

    # ── 可选工具（仅提示）──
    local -a opt_missing=()
    for p in "${OPTIONAL_PKGS[@]}"; do
        is_installed "$p" || opt_missing+=("$p")
    done
    [ ${#opt_missing[@]} -gt 0 ] && printf "  ${CDIM}可选未装: %s${CDEF}\n" "${opt_missing[*]}"

    # ── 安装后提示 ──
    printf "\n"
    info "安装后建议："
    printf "  ${CDIM}·${CDEF} 输入法:   ${CBLD}fcitx5 -r -d${CDEF}\n"
    printf "  ${CDIM}·${CDEF} 电源策略: ${CBLD}sudo systemctl enable --now power-profiles-daemon${CDEF}\n"
    printf "  ${CDIM}·${CDEF} 网络管理: ${CBLD}sudo systemctl enable --now NetworkManager${CDEF}\n"
    printf "  ${CDIM}·${CDEF} 电池保护: 见 ${CBLD}configs/niri/README-battery.md${CDEF}\n"
}

# ── Deploy ──────────────────────────────────────────────
cmd_deploy() {
    local stamp backup rel dst n=0
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$BACKUP_ROOT/deploy-$stamp"

    printf "\n${CBLD}>> 部署配置${CDEF}  ${CDIM}(mode=$MODE -> $DEST)${CDEF}\n"
    rule

    while IFS= read -r rel; do
        dst="$DEST/$rel"
        if [ "$DRY" = 1 ]; then
            printf "  ${CBLU}[%s]${CDEF} configs/%s\n" "$MODE" "$rel"
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mkdir -p "$backup/$(dirname "$rel")"
            copy_entry "$dst" "$backup/$rel" 2>/dev/null || true
        fi
        if [ "$MODE" = "copy" ]; then
            # --remove-destination：目标若还是指向仓库的软链（link→copy 切换），
            # 直接 cp 会报 "are the same file"
            cp -a --remove-destination "$REPO/configs/$rel" "$dst"
        else
            ln -sfn "$REPO/configs/$rel" "$dst"
        fi
        n=$((n + 1))
    done < <(target_files)

    # 登记的命令（configs/scripts/ 源码）→ ~/.local/bin
    while IFS=$'\t' read -r src name; do
        [ -n "${name:-}" ] || continue
        dst="$BIN_DEST/$name"
        if [ "$DRY" = 1 ]; then
            printf "  ${CBLU}[%s]${CDEF} %s -> %s\n" "$MODE" "${src#"$REPO"/}" "$dst"
            continue
        fi
        mkdir -p "$BIN_DEST"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mkdir -p "$backup/local-bin"
            copy_entry "$dst" "$backup/local-bin/$name" 2>/dev/null || true
        fi
        if [ "$MODE" = "copy" ]; then
            cp -aL --remove-destination "$src" "$dst"
        else
            ln -sfn "$src" "$dst"
        fi
        n=$((n + 1))
    done < <(local_bin_targets)

    if [ "$DRY" = 1 ]; then
        info "(dry-run) 未写入任何文件"
        return 0
    fi

    mkdir -p "$backup"
    printf 'Glasveil deploy backup\ncreated: %s\nfiles: %s\nmode: %s\n' \
        "$(date '+%F %T')" "$n" "$MODE" > "$backup/MANIFEST.txt"
    ok "部署了 $n 个文件"
    skip "被覆盖的旧文件已备份到 $backup"
    printf "\n"
    info "后续步骤:"
    printf "  1. 生成配色: ${CBLD}matugen image \"\$(awww query | awk -F 'image: ' '/image: /{print \$2; exit}')\" -t scheme-content -m dark${CDEF}\n"
    printf "  2. 重载:     ${CBLD}niri msg action load-config-file && eww reload${CDEF}\n"
    printf "  3. 电池保护: 见 ${CBLD}configs/niri/README-battery.md${CDEF}\n"
}

# ── Backup / Restore ────────────────────────────────────
cmd_backup() {
    local tag="${1:-$(date +%Y%m%d-%H%M%S)}"
    local out="$BACKUP_ROOT/$tag" rel src n=0
    [ -d "$out" ] && out="$out-$(date +%H%M%S)"

    printf "\n${CBLD}>> 备份当前配置${CDEF}\n"
    rule
    while IFS= read -r rel; do
        src="$DEST/$rel"
        [ -e "$src" ] || [ -L "$src" ] || continue
        if [ "$DRY" = 1 ]; then
            printf "  ${CBLU}[backup]${CDEF} %s\n" "$DEST/$rel"
            n=$((n + 1)); continue
        fi
        mkdir -p "$out/$(dirname "$rel")"
        if [ -L "$src" ]; then
            printf '%s\t%s\n' "$rel" "$(readlink "$src")" >> "$out/LINKS.tsv"
        fi
        copy_entry "$src" "$out/$rel"
        n=$((n + 1))
    done < <(target_files)

    # 登记的命令同样备份（备份目录里用 local-bin/ 区分目标位置）
    while IFS=$'\t' read -r _ name; do
        [ -n "${name:-}" ] || continue
        src="$BIN_DEST/$name"
        [ -e "$src" ] || [ -L "$src" ] || continue
        if [ "$DRY" = 1 ]; then
            printf "  ${CBLU}[backup]${CDEF} %s\n" "$src"
            n=$((n + 1)); continue
        fi
        mkdir -p "$out/local-bin"
        if [ -L "$src" ]; then
            printf '%s\t%s\n' "local-bin/$name" "$(readlink "$src")" >> "$out/LINKS.tsv"
        fi
        copy_entry "$src" "$out/local-bin/$name"
        n=$((n + 1))
    done < <(local_bin_targets)

    if [ "$DRY" = 1 ]; then
        info "(dry-run) 将备份 $n 个文件 -> $out"
        return 0
    fi
    mkdir -p "$out"
    printf 'Glasveil backup\ncreated: %s\nfiles: %s\n' "$(date '+%F %T')" "$n" > "$out/MANIFEST.txt"
    ok "已备份 $n 个文件 -> $out"
}

cmd_restore() {
    local want="${1:-latest}" src="" rel from to n=0
    if [ "$want" = "latest" ]; then
        src="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name 'pre-restore-*' 2>/dev/null | sort | tail -1)"
        [ -n "$src" ] || die "还没有任何备份（$BACKUP_ROOT 为空）"
    elif [ -d "$want" ]; then
        src="$want"
    elif [ -d "$BACKUP_ROOT/$want" ]; then
        src="$BACKUP_ROOT/$want"
    else
        die "找不到备份: $want（用 list-backups 查看）"
    fi

    printf "\n${CBLD}>> 恢复配置${CDEF}  ${CDIM}<- $src${CDEF}\n"
    rule
    [ "$DRY" = 1 ] || cmd_backup "pre-restore-$(date +%Y%m%d-%H%M%S)" >/dev/null

    while IFS= read -r rel; do
        case "$rel" in
            MANIFEST.txt|LINKS.tsv) continue ;;
            local-bin/*) to="$BIN_DEST/${rel#local-bin/}" ;;
            *)           to="$DEST/$rel" ;;
        esac
        from="$src/$rel"
        if [ "$DRY" = 1 ]; then
            printf "  ${CBLU}[restore]${CDEF} %s\n" "$to"
            n=$((n + 1)); continue
        fi
        mkdir -p "$(dirname "$to")"
        rm -rf "$to"
        cp -a "$from" "$to"
        n=$((n + 1))
    done < <(cd "$src" && find . \( -type f -o -type l \) -print | sed 's|^\./||' | sort)

    if [ "$DRY" = 0 ] && [ -f "$src/LINKS.tsv" ]; then
        while IFS=$'\t' read -r rel target; do
            [ -n "${rel:-}" ] || continue
            case "$rel" in
                local-bin/*) to="$BIN_DEST/${rel#local-bin/}" ;;
                *)           to="$DEST/$rel" ;;
            esac
            mkdir -p "$(dirname "$to")"
            ln -sfn "$target" "$to"
        done < "$src/LINKS.tsv"
        skip "已还原 $(wc -l < "$src/LINKS.tsv") 个软链"
    fi

    [ "$DRY" = 1 ] && info "(dry-run) 将恢复 $n 个文件" || ok "已恢复 $n 个文件（$DEST + $BIN_DEST）"
}

cmd_list() {
    printf "\n${CBLD}>> 已有备份${CDEF}\n"
    rule
    if [ ! -d "$BACKUP_ROOT" ] || [ -z "$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ]; then
        skip "还没有任何备份（$BACKUP_ROOT）"
        return 0
    fi
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | while IFS= read -r tag; do
        dir="$BACKUP_ROOT/$tag"
        printf "  %-34s ${CDIM}%4s 个文件   %s${CDEF}\n" "$tag" \
            "$(find "$dir" \( -type f -o -type l \) ! -name MANIFEST.txt ! -name LINKS.tsv | wc -l)" \
            "$(sed -n 's/^created: //p' "$dir/MANIFEST.txt" 2>/dev/null)"
    done
}


# ── Argument Parsing ────────────────────────────────────
COMMAND=""
CMD_ARG=""
REPO_ONLY=0
SAW_FLAG=0

while [ $# -gt 0 ]; do
    case "$1" in
        deploy|deps|all|backup|restore|list-backups|version|help) COMMAND="$1" ;;
        --copy) SAW_FLAG=1;      MODE="copy" ;;
        --link) SAW_FLAG=1;      MODE="link" ;;
        --dry-run) SAW_FLAG=1;   DRY=1 ;;
        --yes|-y)    ASSUME_YES=1 ;;
        --repo-only) SAW_FLAG=1; REPO_ONLY=1 ;;
        -h|--help)   COMMAND="help" ;;
        --*)         die "未知选项: $1（--help 查看用法）" ;;
        *)
            if [ -n "$COMMAND" ] && [ -z "$CMD_ARG" ]; then CMD_ARG="$1"
            elif [ -z "$COMMAND" ]; then die "未知命令: $1（--help 查看用法）"
            else die "多余参数: $1"; fi
            ;;
    esac
    shift
done

# ── Interactive Menu (无参数时) ─────────────────────────
if [ -z "$COMMAND" ] && [ "$SAW_FLAG" = 1 ]; then
    COMMAND="deploy"
fi

# 任意子命令（--dry-run 除外）都顺手保证 glasveil 命令存在
ensure_self_link

if [ -z "$COMMAND" ]; then
    if [ ! -t 0 ]; then
        usage; exit 0
    fi
    while true; do
        show_menu
        printf "  ${CDIM}Select > ${CDEF}"
        read -r choice
        case "$choice" in
            1) cmd_deploy ;;
            2) cmd_deps 0 ;;
            3) cmd_deps 0; cmd_deploy ;;
            4) cmd_backup ;;
            5) cmd_restore latest ;;
            6) cmd_list ;;
            q|Q) echo; exit 0 ;;
            *) warn "无效选择"; continue ;;
        esac
        printf "\n"
    done
fi

# ── Dispatch ────────────────────────────────────────────
case "$COMMAND" in
    deploy)       cmd_deploy ;;
    deps)         cmd_deps "$REPO_ONLY" ;;
    all)          cmd_deps "$REPO_ONLY"; cmd_deploy ;;
    backup)       cmd_backup "$CMD_ARG" ;;
    restore)      cmd_restore "$CMD_ARG" ;;
    list-backups) cmd_list ;;
    version)      printf '%s\n' "$VERSION" ;;
    version)      printf '%s\n' "$VERSION" ;;
    help)         usage ;;
esac
