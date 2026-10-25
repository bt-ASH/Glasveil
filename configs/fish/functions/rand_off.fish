function rand_off -d "关闭 eDP-1 内屏"
    wlr-randr --output eDP-1 --off
    echo "🔴 eDP-1 display off"
end
