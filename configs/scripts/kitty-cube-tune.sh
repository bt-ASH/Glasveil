#!/usr/bin/env bash
# 按明暗模式分别压暗 / 提亮 xterm 256 色立方体
#
#   kitty-cube-tune.sh gen <factor> [--light|--dark]
#       给「当前模式」或指定模式设置缩放系数并重新生成覆盖文件
#       factor < 1 压暗，= 1 不处理，> 1 提亮
#       例：gen 0.65           # 当前是 light 就写入 light=0.65
#           gen 0.9 --dark    # 单独设置 dark 模式的系数
#
#   kitty-cube-tune.sh auto     按当前明暗模式挂/摘 include（开机与切主题时调用）
#   kitty-cube-tune.sh on|off   强制启用/禁用当前模式的覆盖
#   kitty-cube-tune.sh show     查看两种模式当前系数
#
# 系数存在 ~/.cache/kitty-cube-factors，两种模式各自独立；
# 覆盖文件：themes/xterm-cube-light.conf / themes/xterm-cube-dark.conf
# 只动 color16-255，前 16 个主题色（matugen 生成）永远不动。
set -uo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
KITTY_CONF="$CFG_DIR/kitty/kitty.conf"
THEME_DIR="$CFG_DIR/kitty/themes"
MODE_FILE="$HOME/.cache/matugen-strategy/mode"
FACTORS_FILE="$HOME/.cache/kitty-cube-factors"

BEGIN="# >>> cube-tune (per-mode xterm 256 palette)"
END="# <<< cube-tune"

# ── 系数存取 ─────────────────────────────────────────────
factor_of() {   # $1 = light|dark
    local v
    v="$(awk -F= -v m="$1" '$1 == m { print $2; exit }' "$FACTORS_FILE" 2>/dev/null)"
    case "$1:$v" in
        light:) v=0.65 ;;
        dark:)  v=1.0  ;;
        *:)     v=1.0  ;;
    esac
    printf '%s' "$v"
}

factor_set() {  # $1 = light|dark, $2 = value
    local mode="$1" val="$2" tmp
    mkdir -p "$(dirname "$FACTORS_FILE")"
    tmp="$(mktemp)"
    { [ -f "$FACTORS_FILE" ] && grep -E '^(light|dark)=' "$FACTORS_FILE" | grep -v "^$mode=" ; } > "$tmp" || true
    printf '%s=%s\n' "$mode" "$val" >> "$tmp"
    sort -o "$tmp" "$tmp"
    cat "$tmp" > "$FACTORS_FILE"
    rm -f "$tmp"
}

mode_now() { cat "$MODE_FILE" 2>/dev/null || echo dark; }

# ── 生成覆盖文件 ─────────────────────────────────────────
gen_cube() {   # $1 = light|dark, $2 = factor
    local mode="$1" factor="$2"
    local out="$THEME_DIR/xterm-cube-$mode.conf"
    mkdir -p "$THEME_DIR"
    python3 - "$factor" "$out" "$mode" <<'PYGEN'
import sys, pathlib
factor = float(sys.argv[1])
out = pathlib.Path(sys.argv[2])
mode = sys.argv[3]
levels = [0, 95, 135, 175, 215, 255]
def xterm(n):
    if 16 <= n <= 231:
        i = n - 16
        return (levels[i // 36], levels[(i % 36) // 6], levels[i % 6])
    if 232 <= n <= 255:
        v = 8 + 10 * (n - 232)
        return (v, v, v)
    return None
def clip(v):
    return 0 if v < 0 else (255 if v > 255 else int(round(v)))
lines = [
    f"# xterm 256 色立方体 —— {mode} 模式缩放（factor={factor}）",
    "# 由 kitty-cube-tune.sh gen 生成，勿手改",
]
for n in range(16, 256):
    c = xterm(n)
    if c is None:
        continue
    r, g, b = (clip(v * factor) for v in c)
    lines.append(f"color{n} #{r:02x}{g:02x}{b:02x}")
out.write_text("\n".join(lines) + "\n")
print(f"已生成 {out}（{mode}, factor={factor}）")
PYGEN
}

# ── kitty.conf 里的 include 块 ───────────────────────────
apply_include() {   # $1 = light|dark|"" (空=摘掉)
    local mode="$1" tmp
    tmp="$(mktemp)"
    awk '
        index($0, "# >>> cube-tune") == 1 { skip = 1; next }
        index($0, "# <<< cube-tune") == 1 { skip = 0; next }
        !skip { print }
    ' "$KITTY_CONF" > "$tmp"

    if [ -n "$mode" ]; then
        awk -v begin="$BEGIN" -v end="$END" -v inc="include themes/xterm-cube-$mode.conf" '
            /^include __custom__\.conf/ && !done {
                print begin; print inc; print end; print ""; done = 1
            }
            { print }
        ' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"
    fi

    cat "$tmp" > "$KITTY_CONF"      # 原地写入，保住软链
    rm -f "$tmp"
    pkill -SIGUSR1 -x kitty 2>/dev/null || true
}

reconcile() {   # 按当前模式决定挂哪个文件
    local mode f
    mode="$(mode_now)"
    f="$(factor_of "$mode")"
    # 系数为 1.0 视作「不处理」；文件不存在也视作不处理
    if [ "$f" = "1.0" ] || [ "$f" = "1" ] || [ ! -f "$THEME_DIR/xterm-cube-$mode.conf" ]; then
        apply_include ""
        echo "cube-tune: $mode 未启用（factor=$f）"
    else
        apply_include "$mode"
        echo "cube-tune: $mode 启用（factor=$f）"
    fi
}

# ── 参数解析 ─────────────────────────────────────────────
action="${1:-auto}"
case "$action" in
    gen)
        shift
        val=""; target=""
        for a in "$@"; do
            case "$a" in
                --light) target=light ;;
                --dark)  target=dark ;;
                *)       val="$a" ;;
            esac
        done
        [ -n "$val" ] || { echo "用法: kitty-cube-tune.sh gen <factor> [--light|--dark]" >&2; exit 2; }
        [ -n "$target" ] || target="$(mode_now)"
        factor_set "$target" "$val"
        case "$val" in
            1|1.0|1.00)
                rm -f "$THEME_DIR/xterm-cube-$target.conf"
                echo "cube-tune: $target 系数=1.0，已移除覆盖文件（不处理）"
                ;;
            *)
                gen_cube "$target" "$val"
                ;;
        esac
        reconcile
        ;;
    on)
        mode="$(mode_now)"
        f="$(factor_of "$mode")"
        [ -f "$THEME_DIR/xterm-cube-$mode.conf" ] || gen_cube "$mode" "$f"
        apply_include "$mode"
        echo "cube-tune: $mode 强制启用（factor=$f）"
        ;;
    off)
        apply_include ""
        echo "cube-tune: 已移除覆盖"
        ;;
    auto|light|dark)
        reconcile
        ;;
    show)
        printf 'light = %s\ndark  = %s\n' "$(factor_of light)" "$(factor_of dark)"
        ;;
    *)
        echo "usage: kitty-cube-tune.sh gen <factor> [--light|--dark] | auto | on | off | show" >&2
        exit 2
        ;;
esac
