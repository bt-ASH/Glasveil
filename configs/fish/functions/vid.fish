function vid --description '录屏（框选区域，含系统声音）'
    # 注意: fish 用 () 做命令替换, 且必须不加引号地取值;
    # 写成 "(slurp -d)" 会被当成字面字符串传给 wf-recorder, 触发
    # "Bad geometry: (slurp -d), capturing whole output instead." 从而录全屏
    set -l geometry (slurp -d)
    set -l slurp_status $status
    # 用户按 Esc 取消框选时 slurp 返回非 0 且不输出几何信息; 此时提前退出,
    # 避免留下一个空的/坏掉的录制文件
    if test $slurp_status -ne 0 -o -z "$geometry"
        echo '已取消框选' >&2
        return 1
    end

    # 确保输出目录存在
    mkdir -p ~/Videos

    # pactl get-default-sink 只输出一行; 显式取第一行, 以防将来输出多行时
    # 被 fish 展开成多个参数 (那样 --audio 就会多出几个畸形参数)
    set -l sink (pactl get-default-sink | head -n 1)

    wf-recorder -g "$geometry" \
        -f ~/Videos/(date +%Y-%m-%d_%H-%M-%S).mp4 \
        --codec=libx264rgb \
        --audio="$sink.monitor"
end
