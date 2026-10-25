#!/usr/bin/env bash
# ~/.config/niri/scripts/battery-care.sh
# 电池保护（Battery Care）：把电池充电上限锁在 END%（默认 80），下限 START%（默认 75）。
# 由 niri 的 spawn-at-startup 调用；也支持手动 `battery-care.sh --status`。
#
# 说明：/sys/class/power_supply/BAT*/charge_control_end_threshold 默认只有 root 可写。
# 因此本脚本按三级降级：
#   1) 直接写入（若 udev 已给 wheel 组写权限）
#   2) sudo -n 免密写入
#   3) 都没有则只记录日志、静默退出（不阻塞登录）
# 想让它真正生效，用 root 做一次性设置（见 ~/.config/niri/README-battery.md 或下方注释）：
#   /etc/tmpfiles.d/battery-threshold.conf:
#     w /sys/class/power_supply/BAT1/charge_control_end_threshold - - - - 80
#     w /sys/class/power_supply/BAT1/charge_control_start_threshold - - - - 75
#   然后 sudo systemd-tmpfiles --create /etc/tmpfiles.d/battery-threshold.conf

set -uo pipefail

START="${BAT_START:-75}"
END="${BAT_END:-80}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/niri-battery-care.log"

bats() {
    for b in /sys/class/power_supply/BAT*; do
        [ -e "$b/charge_control_end_threshold" ] && printf '%s\n' "$b"
    done
}

write_val() { # <file> <value>
    local file="$1" val="$2"
    printf '%s\n' "$val" >"$file" 2>/dev/null && return 0
    sudo -n sh -c "printf '%s\n' '$val' > '$file'" 2>/dev/null && return 0
    echo "$(date '+%F %T') [battery-care] 无写入权限: $file（需要 root/tmpfiles 一次性设置）" >>"$LOG"
    return 1
}

status() {
    local bat
    for bat in $(bats); do
        printf '%s: start=%s end=%s\n' \
            "$(basename "$bat")" \
            "$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo n/a)" \
            "$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo n/a)"
    done
}

if [ "${1:-}" = "--status" ]; then
    status
    exit 0
fi

changed=0
for bat in $(bats); do
    cur_end="$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "")"
    cur_start="$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "")"
    # 已是最优值就完全不动，避免每次登录都碰一次 root 权限
    if [ "$cur_end" != "$END" ]; then
        write_val "$bat/charge_control_end_threshold" "$END" && changed=1
    fi
    if [ -e "$bat/charge_control_start_threshold" ] && [ "$cur_start" != "$START" ]; then
        write_val "$bat/charge_control_start_threshold" "$START" && changed=1
    fi
done

[ "$changed" = 1 ] && echo "$(date '+%F %T') [battery-care] 阈值已设为 start=$START% end=$END%" >>"$LOG"
exit 0
