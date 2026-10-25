#!/bin/bash

# 延迟收起 tray：鼠标移出后等待 0.6s
# 若期间鼠标回到 tray（tray_pending 被置回 false）则取消收起
# 若 tray_pending 仍为 true 说明确实离开了，才收起

eww update tray_pending=true

sleep 1.7

if [ "$(eww get tray_pending)" = "true" ]; then
    eww update tray_pending=false open_tray=false
fi
