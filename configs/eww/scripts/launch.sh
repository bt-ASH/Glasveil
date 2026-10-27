#!/bin/bash
# 为每个「活动的输出」各开一个 bar
#
# 背景：
#   eww 0.5 的一个 defwindow 只能固定一个 :monitor，多屏要靠
#   `eww open <win> --id barN --screen N` 开多个实例（实例 id 必须不同）。
#   `eww daemon` 是前台进程，直接调用会阻塞脚本，所以这里后台拉起并等 ping。
#   `eww open` 偶尔会卡住（daemon 忙），统一套 timeout，避免脚本卡死。

set -uo pipefail

EWW_TIMEOUT=6

ensure_daemon() {
    timeout 2 eww ping >/dev/null 2>&1 && return 0
    ( setsid eww daemon >/dev/null 2>&1 & )
    i=0
    while [ "$i" -lt 50 ]; do
        timeout 2 eww ping >/dev/null 2>&1 && return 0
        sleep 0.2
        i=$((i + 1))
    done
    echo "eww: daemon 启动失败" >&2
    return 1
}

# 活动输出数量（niri 的 JSON 里只有点亮的输出才有 logical）
active_outputs() {
    local n
    n=$(niri msg --json outputs 2>/dev/null \
        | jq '[to_entries[] | select(.value.logical != null)] | length' 2>/dev/null)
    [ -n "${n:-}" ] && [ "$n" -gt 0 ] 2>/dev/null || n=$(niri msg outputs 2>/dev/null | grep -c '^Output "')
    printf '%s' "${n:-1}"
}

ensure_daemon || exit 1

# 先清掉旧的 bar 实例，避免重复
timeout "$EWW_TIMEOUT" eww close-all >/dev/null 2>&1 || true

count=$(active_outputs)
[ "${count:-0}" -ge 1 ] 2>/dev/null || count=1

i=0
while [ "$i" -lt "$count" ]; do
    timeout "$EWW_TIMEOUT" eww open bar --id "bar$i" --screen "$i" >/dev/null 2>&1 || true
    i=$((i + 1))
done
