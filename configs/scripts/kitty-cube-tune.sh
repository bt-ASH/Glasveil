#!/usr/bin/env bash
# 浅色模式下把 xterm 256 色立方体压暗，解决 TUI 的 256 色语法高亮在浅底上发白
#
#   kitty-cube-tune.sh on     启用（在 kitty.conf 里挂 include themes/xterm-cube-light.conf）
#   kitty-cube-tune.sh off    关闭
#   kitty-cube-tune.sh auto   按当前明暗模式自动 on/off（theme-toggle.sh 会调用）
#
# 只影响 256 色立方体（color16-255），不动前 16 个主题色（那些由 matugen 控制）。
set -uo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
KITTY_CONF="$CFG_DIR/kitty/kitty.conf"
MODE_FILE="$HOME/.cache/matugen-strategy/mode"
BEGIN="# >>> cube-tune (light mode: darken xterm 256 palette)"
END="# <<< cube-tune"
INC="include themes/xterm-cube-light.conf"


CUBE_CONF="$CFG_DIR/kitty/themes/xterm-cube-light.conf"

# 生成 256 色立方体覆盖文件：只压暗「较亮」的颜色（暗色本来就看得清）
#   gen [factor]   默认 0.8（= 压暗 20%），factor 越小越深
gen_cube() {
    local factor="${1:-0.8}"
    mkdir -p "$(dirname "$CUBE_CONF")"
    python3 - "$factor" "$CUBE_CONF" <<'PYGEN'
import sys, pathlib
factor = float(sys.argv[1])
out = pathlib.Path(sys.argv[2])
levels = [0, 95, 135, 175, 215, 255]
def xterm(n):
    if 16 <= n <= 231:
        i = n - 16
        return (levels[i // 36], levels[(i % 36) // 6], levels[i % 6])
    if 232 <= n <= 255:
        v = 8 + 10 * (n - 232)
        return (v, v, v)
    return None
def lum(c):
    r, g, b = [x / 255 for x in c]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
lines = [
    "# xterm 256 色立方体 —— 浅色模式下压暗（供 TUI 的 256 色语法高亮）",
    f"# factor={factor} 由 kitty-cube-tune.sh gen 生成，勿手改",
]
n_tuned = 0
for n in range(16, 256):
    c = xterm(n)
    if c is None:
        continue
    if lum(c) > 0.45:
        c = tuple(int(round(v * factor)) for v in c)
        n_tuned += 1
    lines.append(f"color{n} #{c[0]:02x}{c[1]:02x}{c[2]:02x}")
out.write_text("\n".join(lines) + "\n")
print(f"已生成 {out}（factor={factor}，压暗 {n_tuned} 个颜色）")
PYGEN
}

action="${1:-auto}"
case "$action" in
    gen) gen_cube "${2:-0.8}"; exit 0 ;;
    auto)
        m="$(cat "$MODE_FILE" 2>/dev/null || echo dark)"
        [ "$m" = "light" ] && action=on || action=off
        ;;
    on|off) ;;
    *) echo "usage: kitty-cube-tune.sh on|off|auto" >&2; exit 2 ;;
esac

[ -f "$KITTY_CONF" ] || { echo "找不到 $KITTY_CONF" >&2; exit 1; }

# 先移除已有块
tmp="$(mktemp)"
awk -v b="$BEGIN" -v e="$END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip { print }
' "$KITTY_CONF" > "$tmp"

if [ "$action" = "on" ]; then
    [ -f "$CUBE_CONF" ] || gen_cube 0.8
    # 插到 include __custom__.conf 之前：主题色之后、用户私有配置之前
    awk -v begin="$BEGIN" -v end="$END" -v inc="$INC" '
        /^include __custom__\.conf/ && !done {
            print begin; print inc; print end; print ""; done = 1
        }
        { print }
    ' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"
fi

cat "$tmp" > "$KITTY_CONF"   # 原地写入，保住软链
rm -f "$tmp"
pkill -SIGUSR1 -x kitty 2>/dev/null || true
echo "cube-tune: $action"
