#!/usr/bin/env bash
# Toggle wshowkeys with matugen-generated colors

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config/niri}"
COLORS_FILE="$CONFIG_DIR/wshowkeys/colors.sh"
WKEYS_BG='#00000099'
WKEYS_FG='#FFFFFFFF'
WKEYS_SP='#FF8800FF'

if [ -f "$COLORS_FILE" ]; then
    source "$COLORS_FILE"
fi

if killall -0 wshowkeys 2>/dev/null; then
    killall wshowkeys
else
    wshowkeys -a bottom -a right -m 20 -l 24 -r 15 \
        -b "$WKEYS_BG" -f "$WKEYS_FG" -s "$WKEYS_SP" \
        -F 'monospace 28'
fi
