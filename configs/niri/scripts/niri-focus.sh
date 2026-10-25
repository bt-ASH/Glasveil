#!/usr/bin/env bash
# ~/.config/niri/scripts/niri-focus.sh <niri-focus-action>
#
# 背景：niri 的 focus-column-* / focus-window-* 只作用于平铺窗口；焦点在浮动窗口上时
# 这些动作完全无效（实测 8 个方向动作全都不会移动焦点）。跨越「平铺 ⇄ 浮动」只有
# switch-focus-between-floating-and-tiling 这一个动作。
#
# 本脚本让方向键做到「来回切换」：
#   1) 焦点在浮动窗口  -> 直接切回平铺窗口
#   2) 焦点在平铺窗口  -> 执行原方向动作；若已经到头（焦点没变化）且存在浮动窗口，
#                         则切到浮动窗口（相当于同一方向键再按一下就进浮动）
# 也就是说同一个键能在「不属于浮动窗口」和「浮动窗口」之间来回跳。
set -uo pipefail

action="${1:-}"
[ -n "$action" ] || { echo "usage: niri-focus.sh <niri-focus-action>" >&2; exit 1; }

json="$(niri msg --json focused-window 2>/dev/null)"

# 焦点是不是浮动窗口
if printf '%s' "$json" | grep -q '"is_floating": *true'; then
    niri msg action switch-focus-between-floating-and-tiling
    exit 0
fi

before_id="$(printf '%s' "$json" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)"

# 正常执行方向动作
niri msg action "$action"

# 动作之后焦点没变 = 已经到头了，此时若有浮动窗口就切过去
after_id="$(niri msg --json focused-window 2>/dev/null | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)"
if [ -n "$before_id" ] && [ "$before_id" = "$after_id" ]; then
    if niri msg --json windows 2>/dev/null | grep -q '"is_floating": *true'; then
        niri msg action switch-focus-between-floating-and-tiling
    fi
fi
