#!/bin/bash
# 事件驱动监听默认音频设备类型 (配合 variables.yuck 中的 deflisten 使用)
# 输出: bt / headphone / hands-free / headset / phone / portable / car / default

detect() {
  local sink props name
  sink=$(pactl get-default-sink 2>/dev/null)
  [ -z "$sink" ] && { echo "default"; return; }

  # 提取默认 sink 的 Properties 段
  props=$(pactl list sinks | awk -v s="$sink" '
    $1=="Name:" && $2==s {found=1; next}
    found && /^Sink #/ {exit}
    found {print}
  ')

  # 有线耳机: 耳机插入后 active port 切到 analog-output-headphones
  if echo "$props" | grep -q 'Active Port: analog-output-headphones'; then
    echo "headphone"; return
  fi

  # 蓝牙设备
  if echo "$props" | grep -q 'api.bluez5.profile'; then
    echo "bt"; return
  fi

  name=$(echo "$props" | grep -oP 'device.product.name\s*=\s*"\K[^"]+' | head -1 | tr '[:upper:]' '[:lower:]')
  case "$name" in
    *headset*)   echo "headset" ;;
    *headphone*) echo "headphone" ;;
    *hands-free*|*hands_free*|*handsfree*) echo "hands-free" ;;
    *phone*)     echo "phone" ;;
    *portable*)  echo "portable" ;;
    *car*)       echo "car" ;;
    *)           echo "default" ;;
  esac
}

prev=$(detect)
echo "$prev"

# 监听 Pulse/PipeWire 事件流, 只处理 sink / server (默认 sink 切换) 事件
pactl subscribe 2>/dev/null | while read -r line; do
  case "$line" in
    *"on sink"*|*"on server"*) ;;
    *) continue ;;
  esac

  cur=$(detect)
  if [ "$cur" != "$prev" ]; then
    prev="$cur"
    echo "$cur"
  fi
done
