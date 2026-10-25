# Nyxuri Custom Fish Configuration
#
# Any modifications in this file (such as aliases, exports) will be safely preserved during system updates.
# You can also create a `__custom__/` directory in the current folder to drop your private scripts in.
#
# 任何在此文件中的修改（如 alias、export）都会在系统更新时被安全保留。
# 你也可以在当前目录下创建 __custom__/ 文件夹，把自己的私有脚本都扔进去。
#
# Example / 例如：
# alias ll='ls -alF'
# set -gx EDITOR nvim

# Automatically source all *.fish scripts inside __custom__/ directories if present
# 自动载入 conf.d/__custom__/ 与 ~/.config/fish/__custom__/ 目录下的所有 *.fish 脚本
set -l custom_dirs (status dirname)/__custom__ ~/.config/fish/__custom__
for cdir in $custom_dirs
    if test -d "$cdir"
        for f in "$cdir"/*.fish
            if test -f "$f"
                source "$f"
            end
        end
    end
end

# wifitui 使用 matugen 从壁纸生成的主题（换壁纸后自动更新）
set -gx WIFITUI_THEME "$HOME/.config/wifitui/theme.toml"

# ── 脚本补全（install.sh / niri-health.sh 不在 PATH，需显式 source）──
for __comp in ~/Glasveil/completions/install.sh.fish ~/Scripts-chan/_tools/completions/niri-health.sh.fish
    test -f $__comp; and source $__comp
end
