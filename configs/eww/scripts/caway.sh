#!/usr/bin/env bash

# eww 版 caway：播放时输出 cava 频谱，暂停/停止时输出状态图标（JSON 流）

# 启动时清理残留旧实例（eww reload 不会清理子进程树，孤儿会一直堆积；
# 必须放在拿锁之前，否则旧实例占着锁时新实例直接退出，没人清理）
for pat in "caway.sh" "cava -p /tmp/eww_cava_config" "playerctl -a metadata -F"; do
    for old_pid in $(pgrep -f "$pat"); do
        [ "$old_pid" = "$$" ] && continue
        kill -9 "$old_pid" 2>/dev/null
    done
done

# 防止多实例（清完旧实例后锁一定能拿到）
LOCKFILE="/tmp/eww_caway.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

# 脚本退出时清理子进程
trap "trap - SIGTERM && kill -- -$$ 2>/dev/null" SIGINT SIGTERM

BARS=8
FRAMERATE=10

bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"
i=0
while [ $i -lt ${#bar} ]; do
    dict="${dict}s/$i/${bar:$i:1} /g;"
    i=$((i=i+1))
done
# 去掉每行末尾多余空格
dict="${dict}s/ $//;"

clean_create_pipe() {
    if [ -p "$1" ]; then
        unlink "$1"
    fi
    mkfifo "$1"
}

kill_pid_file() {
    if [[ -f "$1" ]]; then
        while read -r pid; do
            { kill "$pid" && wait "$pid"; } 2>/dev/null
        done < "$1"
    fi
}

cava_pid="/tmp/eww_cava_pid"
cava_pipe="/tmp/eww_cava.fifo"
clean_create_pipe "$cava_pipe"

cava_config="/tmp/eww_cava_config"
cat > "$cava_config" <<EOF
[general]
mode = normal
framerate = $FRAMERATE
bars = $BARS

[output]
method = raw
raw_target = $cava_pipe
data_format = ascii
ascii_max_range = 7
$(if [ -f "$HOME/.cache/matugen/cava-colors.ini" ]; then cat "$HOME/.cache/matugen/cava-colors.ini"; fi)
EOF

# 监听 playerctl 状态（持续运行）
playerctl -a metadata -F --format '{{status}}|{{artist}}|{{title}}' 2>/dev/null | while IFS='|' read -r status artist title; do
    if [[ "$status" == "Playing" ]]; then
        # 先清理旧的 cava 和读取循环，避免累积多个实例
        kill_pid_file "$cava_pid"
        : > "$cava_pid"
        # 启动 cava 输出频谱到管道
        cava -p "$cava_config" > "$cava_pipe" &
        echo $! > "$cava_pid"
        # 后台读 cava 输出，转成频谱字符后输出 JSON
        while read -r cmd2; do
            text=$(echo "$cmd2" | sed "$dict")
            jq -c -n --arg text "$text" --arg title "$title" --arg artist "$artist" --arg status "$status" \
                '{text:$text,title:$title,artist:$artist,status:$status}'
        done < "$cava_pipe" &
        echo $! >> "$cava_pid"
    else
        kill_pid_file "$cava_pid"
        if [[ "$status" == "Paused" ]]; then
            icon=""
        else
            icon="ﭥ"
        fi
        jq -c -n --arg text "$icon" --arg title "$title" --arg artist "$artist" --arg status "$status" \
            '{text:$text,title:$title,artist:$artist,status:$status}'
    fi
done
