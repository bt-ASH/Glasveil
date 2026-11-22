#!/usr/bin/env bash
# 重启 mako 通知守护进程。
#
# 原来的写法 `killall mako & sleep 0.1 && mako &` 有两个问题：
#   1. 固定 sleep 0.1 是竞态：mako 还没退干净就起新的，会抢不到
#      org.freedesktop.Notifications（旧进程仍占着 D-Bus 名字）；
#   2. `mako &` 继承了调用者的 stdin/stdout/stderr，从终端或脚本里
#      调用时会把调用者挂住（输出管道不关，caller 一直等 EOF）。

set -u

if pgrep -x mako >/dev/null 2>&1; then
    pkill -x mako

    # 轮询等它真正退出（最多约 2s），而不是盲等一个固定时长
    for _ in $(seq 1 100); do
        pgrep -x mako >/dev/null 2>&1 || break
        sleep 0.02
    done
fi

# setsid -f：脱离当前会话/进程组，且三处重定向切断与调用者的继承关系
setsid -f mako >/dev/null 2>&1 < /dev/null
