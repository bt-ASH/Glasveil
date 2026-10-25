#!/bin/bash
# 监听显示器(输出)变化, 变化时重新为每个输出开一个 bar
#
# 说明: niri 26.04 的 `niri msg --json event-stream` 不发输出变化事件
# (实测改 scale、改 transform 都不会发任何事件, 事件流里只有 WorkspacesChanged /
# WindowsChanged 这类, 没有 OutputsChanged), 所以这里用轮询 + 快照对比。
# 只有输出的名字集合发生变化(插拔屏)时才重开 bar, 改分辨率/缩放不会触发。

# flock 保证单实例: 旧实例活着持锁时新实例直接退出, 不会堆积;
# 不做 kill 旧实例 (并发启动时互相 kill -9 会同归于尽, 还会误杀 cmdline 带脚本名的父进程)
LOCKFILE="/tmp/eww_watch_outputs.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

LAUNCH="$HOME/.config/eww/scripts/launch.sh"

snapshot() {
    niri msg outputs | sed -n 's/^Output .*(\([^)]*\))$/\1/p' | sort
}

# 当前已打开的 bar 实例数 (eww active-windows 输出形如 "bar0: bar")
bars_open() {
    eww active-windows 2>/dev/null | grep -c '^bar[0-9]*:'
}

prev=$(snapshot)

while true; do
    sleep 2
    cur=$(snapshot)
    [ "$cur" = "$prev" ] && continue
    prev=$cur
    [ -z "$cur" ] && continue
    sleep 1 # 等 niri 把新输出准备好
    bash "$LAUNCH"
    # 校验: eww 有时来不及识别新插的输出, 导致部分 bar 开失败, 补开一次
    sleep 2
    if [ "$(bars_open)" -lt "$(echo "$cur" | grep -c .)" ]; then
        sleep 2
        bash "$LAUNCH"
    fi
done
