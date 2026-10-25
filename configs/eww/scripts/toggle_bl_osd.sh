#!/bin/bash
# toggle_bl_osd.sh — 一键开关屏幕亮度（点一下熄屏，再点恢复）
# 依赖 brightnessctl（backlight.yuck 的亮度图标滑动也在用）
# 熄屏前把当前亮度存到 state 文件，恢复时读回。

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/eww_bl_os_state"

cur=$(brightnessctl -m 2>/dev/null | head -1 | awk -F, '{print $4}' | tr -d '%')
cur=${cur%.*}

if [ -z "$cur" ]; then
    exit 1
fi

if [ "$cur" -gt 0 ]; then
    # 熄屏：记录当前亮度
    echo "$cur" > "$STATE_FILE"
    brightnessctl set 0 2>/dev/null
else
    # 恢复亮度
    if [ -f "$STATE_FILE" ]; then
        prev=$(cat "$STATE_FILE")
        rm -f "$STATE_FILE"
    else
        prev=50
    fi
    brightnessctl set "${prev}%" 2>/dev/null
fi