#!/bin/bash
# niri workspaces -> eww JSON array
# no args: one-shot output of current state
# --listen: keep running, print new JSON on niri workspace events (for eww deflisten)

get() {
    niri msg --json workspaces 2>/dev/null | jq -c '[.[] | {id: .idx, focused: .is_focused}] | sort_by(.id)'
}

if [ "$1" = "--listen" ]; then
    get
    niri msg --json event-stream 2>/dev/null | while read -r line; do
        case "$line" in
            *WorkspacesChanged*|*WorkspaceActivated*) get ;;
        esac
    done
else
    get
fi
