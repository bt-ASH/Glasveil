#!/bin/bash
COLORS_CSS="$HOME/.config/waybar/colors.css"
BG="#151218"
ALPHA=$((0xE6))

hex() { printf "%02X" "$1"; }

blend() {
    local fg=$1 bg=$2 a=$ALPHA
    echo $(( (fg * a + bg * (255 - a)) / 255 ))
}

# 始终从 primary_fixed_dim 读取原始值（matugen 原始输出，不被脚本修改）
ORIG=$(grep -oP '@define-color primary_fixed_dim\s+\K#[0-9a-fA-F]{6}' "$COLORS_CSS")
[ -z "$ORIG" ] && exit 1

R1=$((16#${ORIG:1:2}))
G1=$((16#${ORIG:3:2}))
B1=$((16#${ORIG:5:2}))
R2=$((16#${BG:1:2}))
G2=$((16#${BG:3:2}))
B2=$((16#${BG:5:2}))

R=$(blend $R1 $R2)
G=$(blend $G1 $G2)
B=$(blend $B1 $B2)
NEW="#$(hex $R)$(hex $G)$(hex $B)"

sed -i "s/@define-color primary .*/@define-color primary $NEW;/" "$COLORS_CSS"
