function rand_on -d "开启 eDP-1 内屏"
    wlr-randr --output eDP-1 --on
    echo "🟢 eDP-1 display on"
end
