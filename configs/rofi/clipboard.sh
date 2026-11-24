#!/usr/bin/env bash
# ── rofi 剪贴板历史（clipse → rofi → wl-copy）────────────────────────────────
# niri 键位：Mod+Shift+V（configs/niri/__custom__.kdl）
# 主题：~/.config/rofi/clipboard.rasi（配色来自 matugen 渲染的 colors.rasi）
#
# clipse 1.2 只有 TUI，没有 list/decode 子命令，所以直接读它的历史文件：
#   ~/.config/clipse/clipboard_history.json
#   {"clipboardHistory":[{"value":"...","recorded":"...","filePath":"null"|路径,"pinned":false}]}
# 文本条目复制 value，图片条目按 filePath 用对应 MIME 写回剪贴板。
set -uo pipefail

CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
HIST="$CONF/clipse/clipboard_history.json"
THEME="$CONF/rofi/clipboard.rasi"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a Clipboard "剪贴板" "$1"; }

[ -r "$HIST" ] || { notify "找不到 clipse 历史: $HIST"; exit 1; }
command -v jq >/dev/null 2>&1 || { notify "需要 jq"; exit 1; }
command -v rofi >/dev/null 2>&1 || { notify "需要 rofi"; exit 1; }

# 1) 按时间倒序排列；关掉空条目，文本压成单行、截断到 100 字，图片显示文件名。
#    索引单独取一份，保证与显示行一一对应（rofi -format i 返回的是行号）。
filter='
  .clipboardHistory
  | to_entries
  | map(select(((.value.value // "") != "") or ((.value.filePath // "null") != "null")))
  | sort_by(.value.recorded)
  | reverse
'

mapfile -t keys < <(jq -r "$filter"' | .[].key' "$HIST" 2>/dev/null)
mapfile -t rows < <(jq -r "$filter"'
    | .[]
    | if (.value.filePath // "null") != "null"
        then "[图片] " + (.value.filePath | split("/") | last)
        else (.value.value | gsub("\\s+"; " ") | .[0:100])
      end
  ' "$HIST" 2>/dev/null)

if [ "${#rows[@]}" -eq 0 ]; then
    notify "剪贴板历史为空"
    exit 0
fi

# 2) rofi 选择：-format i 只回行号，界面里看不到内部索引
idx="$(printf '%s\n' "${rows[@]}" |
    rofi -dmenu -i -no-custom -p "" -format i -theme "$THEME" 2>/dev/null)" || exit 0
[ -n "${idx:-}" ] || exit 0

key="${keys[$idx]:-}"
[ -n "$key" ] || exit 0

# 3) 写回剪贴板：图片按原 MIME，文本原样（保留换行）
file="$(jq -r --argjson k "$key" '.clipboardHistory[$k].filePath // "null"' "$HIST")"
if [ "$file" != "null" ] && [ -f "$file" ]; then
    mime="$(file --mime-type -b "$file" 2>/dev/null || echo application/octet-stream)"
    wl-copy --type "$mime" < "$file"
else
    jq -j --argjson k "$key" '.clipboardHistory[$k].value // empty' "$HIST" | wl-copy
fi
