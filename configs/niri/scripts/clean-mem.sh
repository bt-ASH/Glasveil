#!/usr/bin/env bash
# ~/.config/niri/scripts/clean-mem.sh
# 清理内存缓存和 swap，解决待机久了内存溢出问题
# 需要 sudo 权限（执行时会弹出密码输入框）
#
# 用法：
#   clean-mem.sh                    # 清理缓存 + swap
#   clean-mem.sh --dry-run          # 只看当前状态，不做清理
#   clean-mem.sh --cron             # 安静模式（给定时任务用）

set -e

dry_run=false
quiet=false
[ "$1" = "--dry-run" ] && dry_run=true
[ "$1" = "--cron" ] && quiet=true

# ─── 清理前统计 ──
MEM_BEFORE=$(free -h | awk '/Mem:/{print $3}')
SWAP_BEFORE=$(free -h | awk '/Swap:/{print $3}')
CACHE_BEFORE=$(free -h | awk '/Mem:/{print $6}')

$quiet || echo "Before: RAM: $MEM_BEFORE | Swap: $SWAP_BEFORE | Cache: $CACHE_BEFORE"
$quiet || echo ""

# ─── 1. 清理缓存 ──
$quiet || echo "▶ Dropping caches (pagecache / dentries / inodes)..."
if ! $dry_run; then
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || \
        echo "  ⚠  sudo failed, skipping cache drop"
fi

# ─── 2. 清理 swap ──
SWAP_CURRENT=$(free | awk '/Swap:/{print $3}')
if [ "$SWAP_CURRENT" != "0" ]; then
    $quiet || echo "▶ Reclaiming swap (swapoff + swapon)..."
    if ! $dry_run; then
        FREE_RAM=$(free | awk '/Mem:/{print $7}')
        SWAP_USED=$(free | awk '/Swap:/{print $3}')
        if [ "$FREE_RAM" -gt "$SWAP_USED" ]; then
            sudo swapoff -a && sudo swapon -a
            $quiet || echo "  ✅ Swap reclaimed"
        else
            $quiet || echo "  ⚠  Not enough free RAM to clear swap, skipping"
        fi
    fi
else
    $quiet || echo "▶ Swap already empty"
fi

# ─── 3. 清理完成统计 ──
if ! $dry_run; then
    MEM_AFTER=$(free -h | awk '/Mem:/{print $3}')
    SWAP_AFTER=$(free -h | awk '/Swap:/{print $3}')
    CACHE_AFTER=$(free -h | awk '/Mem:/{print $6}')
    $quiet || echo ""
    $quiet || echo "After: RAM: $MEM_AFTER | Swap: $SWAP_AFTER | Cache: $CACHE_AFTER"
    $quiet || echo "✅ Done"
fi

# ─── 4. 记录日志（cron 模式）──
if [ "$1" = "--cron" ]; then
    LOG="$HOME/.cache/clean-mem.log"
    echo "[$(date '+%Y-%m-%d %H:%M')] RAM: ${MEM_BEFORE}->${MEM_AFTER} | Swap: ${SWAP_BEFORE}->${SWAP_AFTER} | Cache: ${CACHE_BEFORE}->${CACHE_AFTER}" >> "$LOG"
fi
