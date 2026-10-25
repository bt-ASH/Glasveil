function fish_prompt --description "双行药丸提示符（配色跟随 kitty 主题）"
    set -l st $status

    # ── 配色：实时读取 kitty 当前主题（~/.config/kitty/current-theme.conf）──
    # 想换映射就改这里的 kitty 颜色键名；第二个参数是读不到时的兜底值。
    # 常用键：background foreground color0-15 selection_background active_border_color
    set -l c_pill (_nyx_kitty_color active_border_color 5b6fb0)  # 常态药丸底色（主题强调色）
    set -l c_err  (_nyx_kitty_color color1               a34a4a)  # 出错药丸底色
    set -l c_on   (_nyx_kitty_color background           12131b)  # 药丸内文字
    set -l c_text (_nyx_kitty_color foreground           c9c9dc)  # 普通文字（目录）
    set -l c_sym  (_nyx_kitty_color active_border_color  8b9ee0)  # 常态提示符符号
    set -l c_esym (_nyx_kitty_color color1               d16868)  # 出错提示符符号

    # ── 依上一条命令退出码切换整行配色 ──
    if test $st -eq 0
        set pill $c_pill
        set sym  "  ●"
        set scol $c_sym
    else
        set pill $c_err
        set sym  "  ✕"
        set scol $c_esym
    end

    # ── 上一条命令耗时（$CMD_DURATION 为毫秒）──
    set -l ms $CMD_DURATION
    test -z "$ms"; and set ms 0
    set -l s (math "floor($ms / 1000)")
    if test $s -ge 3600
        set dur (math "floor($s / 3600)")h(math "floor(($s % 3600) / 60)")m
    else if test $s -ge 60
        set dur (math "floor($s / 60)")m(math "$s % 60")s
    else
        set dur "$s""s"
    end

    # ── 第一行：[⏱ 耗时]  目录  [工程图标 / git分支] ──
    _nyx_pill $pill $c_on "󱎫 $dur"
    printf ' '
    set_color $c_text
    printf '%s' (prompt_pwd)
    set_color normal
    printf ' '
    # 药丸内容（对齐 fish0 / starship：只有工程图标和 git 分支，没有别的装饰）
    #   有工程 + 有 git → "<工程图标>  <git图标 分支>"
    #   只有 git       → "<git图标 分支>"
    #   只有工程       → "<工程图标>"
    #   都没有         → "󰉋"
    set -l proj (_nyx_dir_icon)
    set -l gitinfo (_nyx_git_info)
    set -l tag
    if test -n "$proj"; and test -n "$gitinfo"
        set tag "$proj  $gitinfo"
    else if test -n "$gitinfo"
        set tag "$gitinfo"
    else if test -n "$proj"
        set tag "$proj"
    else
        set tag "󰉋"
    end
    _nyx_pill $pill $c_on "$tag"
    printf '\n'

    # ── 第二行：● ➤ / ✕ ➤ ──
    set_color --bold $scol
    printf '%s ➤ ' $sym
    set_color normal
end
