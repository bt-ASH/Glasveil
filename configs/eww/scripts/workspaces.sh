#!/usr/bin/env bash
# niri workspaces -> eww JSON array
#
#   workspaces.sh [输出名]            # 一次性输出（不填=全部输出）
#   workspaces.sh --listen [输出名]   # 订阅 niri 事件流（供 eww deflisten）
#
# 多屏时每条 bar 只显示自己那块屏的工作区：
# 用 niri 的 `output` 字段过滤，用 `is_active`（该输出上可见的工作区）
# 而不是 `is_focused`（全局焦点屏），这样非焦点屏的 bar 也能正确高亮。
OUTPUT=""
LISTEN=0

case "${1:-}" in
    --listen) LISTEN=1; OUTPUT="${2:-}" ;;
    "")       OUTPUT="" ;;
    *)        OUTPUT="$1" ;;
esac

get() {
    niri msg --json workspaces 2>/dev/null | jq -c --arg out "$OUTPUT" '
        [ .[] | select($out == "" or .output == $out)
          | {id: .idx, focused: .is_active} ]
        | sort_by(.id)'
}

if [ "$LISTEN" = 1 ]; then
    get
    niri msg --json event-stream 2>/dev/null | while read -r line; do
        case "$line" in
            *WorkspacesChanged*|*WorkspaceActivated*) get ;;
        esac
    done
else
    get
fi
