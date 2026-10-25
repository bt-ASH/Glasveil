function sspreview --description "批量预览 starship 预设（用临时配置渲染，不修改正式配置）"
    # 可用预设列表（过滤掉 --list 尾部的空行）
    set -l all
    for name in (starship preset --list)
        test -n "$name"; and set -a all $name
    end
    set -l chosen $all
    if test (count $argv) -gt 0
        set chosen $argv
    end

    # 搭建预览环境：临时 git 仓库 + 常见语言标记文件
    # 这样目录 / git / 语言模块都能显示出来，方便对比
    set -l demo /tmp/ss-preview-demo
    if not test -d $demo/.git
        command mkdir -p $demo
        git -C $demo init -q
        git -C $demo -c user.email=preview@local -c user.name=preview commit -q --allow-empty -m init
        echo "print('hi')" > $demo/main.py
        touch $demo/package.json $demo/Cargo.toml $demo/README.md
    end

    set -l tmp /tmp/starship-preview.toml
    for p in $chosen
        if not contains -- $p $all
            set_color red; echo "  跳过未知预设: $p"; set_color normal
            continue
        end
        starship preset $p > $tmp 2>/dev/null
        echo
        set_color --bold brcyan; echo "══════ $p ══════"; set_color normal
        pushd $demo >/dev/null
        env STARSHIP_CONFIG=$tmp starship prompt --terminal-width=100 --cmd-duration=1500
        popd >/dev/null
    end
    echo
    set_color brblack
    echo "提示：满意的话 → starship preset <名字> -o ~/.config/starship.toml  然后 exec fish"
    echo "      想临时试某个 → starship preset <名字> > /tmp/p.toml; set -x STARSHIP_CONFIG /tmp/p.toml; exec fish"
    set_color normal
end
