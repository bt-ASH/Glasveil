function _nyx_kitty_color --description "取 kitty 当前主题颜色：_nyx_kitty_color <键> [兜底值]"
    set -l key $argv[1]
    set -l fallback $argv[2]
    set -l conf ~/.config/kitty/current-theme.conf

    if test -r $conf
        # 按文件 mtime 缓存整份配色，避免每次提示符都重复读盘
        set -l mt (stat -c %Y $conf 2>/dev/null; or stat -f %m $conf 2>/dev/null)
        if not set -q _nyx_kitty_mt; or test "$_nyx_kitty_mt" != "$mt"
            set -g _nyx_kitty_mt "$mt"
            set -g _nyx_kitty_lines (cat $conf)
        end

        # 只匹配行首关键字，避免 background 命中 selection_background 之类
        set -l m (string match -r -g -- "^\s*$key\s+(\S+)" $_nyx_kitty_lines)
        if test -n "$m"
            echo $m[1]
            return 0
        end
    end

    # 读不到就退回兜底值
    test -n "$fallback"; and echo $fallback
    return 0
end
