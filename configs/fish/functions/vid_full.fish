function vid_full --description '录屏（当前焦点输出全屏，含系统声音）'
    # niri 输出 JSON 中不带 sway 的 .focused 字段, 直接用 focused-output 子命令;
    # logical 是逻辑坐标(受 scale 影响), 正是 wf-recorder -g 需要的单位
    set -l geometry (niri msg --json focused-output | jq -r '.logical | "\(.x),\(
.y) \(.width)x\(.height)"')
    if test -z "$geometry" -o "$geometry" = "null"
        echo '未找到焦点输出' >&2
        return 1
    end
    wf-recorder -g "$geometry" \
        -f ~/Videos/(date +%Y-%m-%d_%H-%M-%S).mp4 \
        --codec=libx264rgb \
        --audio=(pactl get-default-sink).monitor
end
