#!/usr/bin/env bash
# 把 matugen 渲染好的 Glasveil 配色合并进 Spicetify 的 color.ini
#
#   源：  ~/.cache/matugen/spotify-color.ini              （matugen 每次换壁纸重写）
#         回退：~/.config/matugen/spotify-color.fallback.ini（还没跑过 matugen 时用）
#   目标：~/.config/spicetify/Themes/<theme>/color.ini
#
# 只做 [Glasveil] / [Glasveil-Dark] 两个 section 的替换，文件里其它 section
# （[Marketplace] / [ZedMatch] / [ZedMatch-Dark] …）原样保留，绝不整文件覆盖。
# 所有颜色值统一转成「不带井号的 6 位大写十六进制」——Spicetify 的硬性要求。
# 不调用 spicetify apply（那是 install.sh 的活，换壁纸后想立刻生效加 --apply）。
#
# 用法:
#   inject-spicetify-color.sh [-s 源文件] [-t 目标 color.ini] [-n|--dry-run] [--apply]

set -euo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"

STAGED="$CACHE_DIR/matugen/spotify-color.ini"
FALLBACK="$CFG_DIR/matugen/spotify-color.fallback.ini"
SRC=""                                    # 空 = 自动选 staged / fallback
TGT="$CFG_DIR/spicetify/Themes/marketplace/color.ini"
DRY=0
APPLY=0

usage() {
    cat <<'USAGE'
用法: inject-spicetify-color.sh [-s 源文件] [-t 目标 color.ini] [-n|--dry-run] [--apply]

  -s, --source <file>   配色源（默认 ~/.cache/matugen/spotify-color.ini，
                        不存在时回退 ~/.config/matugen/spotify-color.fallback.ini）
  -t, --target <file>   目标 color.ini（默认 spicetify/Themes/marketplace/color.ini）
  -n, --dry-run         只打印将要做的事
      --apply           合并后调用 spicetify apply -n 让 Spotify 立刻生效
  -h, --help            显示本帮助
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--source)  SRC="${2:-}"; shift 2 ;;
        -t|--target)  TGT="${2:-}"; shift 2 ;;
        -n|--dry-run) DRY=1; shift ;;
        --apply)      APPLY=1; shift ;;
        -h|--help)    usage; exit 0 ;;
        *) printf '未知参数: %s（-h 查看用法）\n' "$1" >&2; exit 2 ;;
    esac
done

command -v python3 >/dev/null 2>&1 || { printf '缺少 python3，无法合并 color.ini\n' >&2; exit 1; }

# ── 选源：显式指定 > matugen 暂存 > 仓库里的回退快照 ──
if [ -z "$SRC" ]; then
    if [ -f "$STAGED" ]; then
        SRC="$STAGED"
    elif [ -f "$FALLBACK" ]; then
        SRC="$FALLBACK"
        printf '· 还没跑过 matugen，用回退快照: %s\n' "$FALLBACK"
    else
        printf '找不到配色源（%s 与 %s 都不存在）\n' "$STAGED" "$FALLBACK" >&2
        exit 1
    fi
fi
[ -f "$SRC" ] || { printf '配色源不存在: %s\n' "$SRC" >&2; exit 1; }

# 没装 Spicetify 就别在人家配置目录里造文件
if [ ! -d "$CFG_DIR/spicetify" ] && ! command -v spicetify >/dev/null 2>&1; then
    printf '· 未检测到 Spicetify（%s 不存在），跳过 Spotify 配色\n' "$CFG_DIR/spicetify"
    exit 0
fi

mkdir -p "$(dirname "$TGT")"
[ -f "$TGT" ] || : > "$TGT"

# 首次改动前留一份不可再生的原始备份（之后每次只替换两个 section，无需再备）
ORIG_BAK="$TGT.pre-glasveil.bak"

if [ "$DRY" = 1 ]; then
    printf '[dry-run] 合并 %s -> %s\n' "$SRC" "$TGT"
    [ -f "$ORIG_BAK" ] || printf '[dry-run] 将备份原始文件到 %s\n' "$ORIG_BAK"
    exit 0
fi

[ -f "$ORIG_BAK" ] || cp -a "$TGT" "$ORIG_BAK"

# ── 规范化 + section 级合并（python3 只做文本处理，无第三方依赖）──
python3 - "$SRC" "$TGT" "$ORIG_BAK" <<'PY'
import os
import re
import sys
import tempfile

src_path, tgt_path, bak_path = sys.argv[1:4]
OWN = ("Glasveil", "Glasveil-Dark")
HEX = re.compile(r"^[0-9A-Fa-f]{6}$")
HEADER = re.compile(r"^\s*\[([^\]]+)\]\s*$")
PAIR = re.compile(r"^\s*([A-Za-z0-9_.-]+)\s*=\s*(.*?)\s*$")


def normalize(text):
    """模板输出 -> 合法 ini 行；颜色一律去井号转大写，坏值丢弃并告警。"""
    out, seen = [], set()
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            out.append("")
            continue
        if stripped.startswith((";", "#")):
            out.append(stripped)
            continue
        h = HEADER.match(stripped)
        if h:
            out.append("[%s]" % h.group(1).strip())
            continue
        p = PAIR.match(line)
        if not p:
            print("  · 跳过无法解析的行: %s" % stripped, file=sys.stderr)
            continue
        key, val = p.group(1), p.group(2).lstrip("#").strip()
        if not HEX.match(val):
            print("  · 跳过非法颜色 %s = %s" % (key, val), file=sys.stderr)
            continue
        seen.add(key)
        out.append("%-18s = %s" % (key, val.upper()))
    return out, seen


def _is_lead(line):
    """注释行/空行：可以跟着它下面的 section 一起被替换掉。"""
    s = line.strip()
    return not s or s.startswith((";", "#"))


def own_spans(lines):
    """算出要删掉的行区间 [start, end)：OWN section 本体 + 紧邻的注释/空行。
    其它 section 一个字节都不碰（文件头的注释也不会被吃掉）。"""
    heads = [(i, HEADER.match(l).group(1).strip())
             for i, l in enumerate(lines) if HEADER.match(l)]
    spans = []
    for pos, (start, name) in enumerate(heads):
        if name not in OWN:
            continue
        end = heads[pos + 1][0] if pos + 1 < len(heads) else len(lines)
        # 往前吞掉紧贴着的注释/空行（模板注释随 section 一起换，避免重复堆积）
        while start > 0 and _is_lead(lines[start - 1]):
            if all(_is_lead(l) for l in lines[:start]):   # 上面全是注释 = 文件头，别吞
                break
            start -= 1
        # 往后停在最后一个非空行（保留 section 之间的空行做分隔）
        while end > start and not lines[end - 1].strip():
            end -= 1
        if spans and start <= spans[-1][1]:
            spans[-1][1] = max(spans[-1][1], end)
        else:
            spans.append([start, end])
    return spans


with open(src_path, encoding="utf-8") as fh:
    new_lines, keys = normalize(fh.read())

names = {HEADER.match(l).group(1).strip() for l in new_lines if HEADER.match(l)}
missing = [s for s in OWN if s not in names]
if missing:
    sys.exit("配色源缺少 section: %s（%s 不是合法的 matugen 产物？）"
             % (", ".join(missing), src_path))

with open(tgt_path, encoding="utf-8") as fh:
    old_lines = fh.read().splitlines()

old_names = [HEADER.match(l).group(1).strip() for l in old_lines if HEADER.match(l)]
dropped = [n for n in old_names if n in OWN]
kept_names = [n for n in old_names if n not in OWN]

drop = set()
for start, end in own_spans(old_lines):
    drop.update(range(start, end))

kept = [l for i, l in enumerate(old_lines) if i not in drop]
while kept and not kept[-1].strip():
    kept.pop()

body = "\n".join(kept)
out = (body + "\n\n" if body else "") + "\n".join(new_lines).strip("\n") + "\n"

fd, tmp = tempfile.mkstemp(dir=os.path.dirname(tgt_path) or ".", prefix=".color.ini.")
try:
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(out)
    os.chmod(tmp, 0o644)
    os.replace(tmp, tgt_path)
except BaseException:
    os.unlink(tmp)
    raise

print("· 已写入 %s（替换 %s；保留其它 %d 个 section，%d 个颜色键）"
      % (tgt_path,
         "/".join(sorted(set(dropped))) or "无旧 section",
         len(kept_names),
         len([ln for ln in new_lines if PAIR.match(ln)])))
print("· 原始文件备份: %s" % bak_path)
PY

# ── 可选：立刻让 Spotify 吃到新配色（默认不做，换壁纸时由用户/install.sh 决定）──
if [ "$APPLY" = 1 ]; then
    if command -v spicetify >/dev/null 2>&1; then
        spicetify apply -n >/dev/null 2>&1 || printf '· spicetify apply 失败（Spotify 未安装/未打补丁？）\n' >&2
    else
        printf '· 未找到 spicetify，跳过 apply\n' >&2
    fi
fi

exit 0
