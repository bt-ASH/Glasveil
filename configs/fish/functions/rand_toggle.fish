function rand_toggle -d "切换 eDP-1 内屏开关"
    # 只取 eDP-1 那一段（wlr-randr --output 不会过滤，必须自己截取区块）
    set -l state (wlr-randr | awk '/^eDP-1 /{p=1;next} /^[^[:space:]]/{p=0} p' | string match -r 'Enabled:\s*(yes|no)')

    if test "$state[2]" = "yes"
        wlr-randr --output eDP-1 --off
        echo "🔴 eDP-1 display off"
    else
        wlr-randr --output eDP-1 --on
        echo "🟢 eDP-1 display on"
    end
end
