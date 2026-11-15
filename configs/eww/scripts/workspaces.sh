#!/usr/bin/env bash
# niri workspaces -> eww JSON array
#
#   workspaces.sh [输出名]                # 一次性输出（不填=全部输出）
#   workspaces.sh --listen [输出名]       # 订阅 niri 事件流（供 eww deflisten）
#   workspaces.sh --slot N                # 一次：只列第 N 块活动输出
#   workspaces.sh --listen --slot N       # 同上，配合 bar$N 的 :monitor N
#
# 多屏时每条 bar 只显示自己那块屏的工作区。
#
# 为什么按 slot 而不是写死输出名：
#   launch.sh 按「活动输出序号」开 bar$N，eww 的 :monitor 也吃序号，而输出名
#   会随插拔变化。曾经写死 DP-1 / eDP-1，只剩一块屏时 bar0 仍挂在 DP-1 上，
#   过滤结果恒为 []，整条 bar 就不显示工作区了。
#   这里每轮把序号解析成当前真实输出名，两边共用同一套序号，插拔后自动对齐。
#
# 过滤用 `is_active`（该输出上当前可见）而不是 `is_focused`（全局焦点屏），
# 这样非焦点屏的 bar 也能正确高亮。
OUTPUT=""
SLOT=""
LISTEN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --listen) LISTEN=1; shift ;;
        --slot)   SLOT="${2:?--slot 需要序号}"; shift 2 ;;
        *)        OUTPUT="$1"; shift ;;
    esac
done

# 第 N 块点亮的输出叫什么（序号的取法与 eww 的 :monitor 一致）
slot_output() {
    niri msg --json outputs 2>/dev/null | jq -r --argjson n "$1" '
        [ to_entries[] | select(.value.logical != null) ]
        | .[$n].key // empty'
}

get() {
    local out="$OUTPUT"
    if [ -n "$SLOT" ]; then
        out=$(slot_output "$SLOT")
        # 这块屏还没就绪就先给空表，等事件流下一轮刷新
        # 注意必须带换行：deflisten 按行读，没有 \n 这一帧可能压根不生效
        if [ -z "$out" ]; then
            printf '[]\n'
            return 0
        fi
    fi
    niri msg --json workspaces 2>/dev/null | jq -c --arg out "$out" '
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
