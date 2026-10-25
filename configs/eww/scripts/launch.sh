#!/bin/bash
# 为每个已连接的输出各开一个 bar 实例
# 注意: eww 0.5 只能用 monitor 索引, 且索引顺序跟屏幕左右位置无关
# 索引由 wl_output 出现顺序决定, 插拔屏幕后可能变化, 所以这里按当前连接数量逐个开

sleep 1

eww daemon
eww close-all 2>/dev/null

count=$(niri msg outputs | grep -c '^Output "')

for ((i = 0; i < count; i++)); do
    eww open bar --id "bar$i" --screen "$i"
done
