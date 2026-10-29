# fish completion for Glasveil install.sh
# 用法: cp ~/Glasveil/configs/fish/completions/install.sh.fish ~/.config/fish/completions/
set -l __gv_cmds deploy deps all backup restore list-backups completion help

complete -c install.sh -f

complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a deploy       -d "只部署配置到 ~/.config"
complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a deps         -d "只安装依赖（仓库包 + AUR）"
complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a all          -d "先装依赖再部署"
complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a backup       -d "备份当前配置"
complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a restore      -d "回滚到某个备份"
complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a list-backups -d "列出已有备份"
complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a completion   -d "输出 shell 补全脚本"
complete -c install.sh -n "not __fish_seen_subcommand_from $__gv_cmds" -a help         -d "显示帮助"

complete -c install.sh -n "__fish_seen_subcommand_from completion" -a "bash fish zsh" -d "shell 类型"
complete -c install.sh -n "__fish_seen_subcommand_from restore" \
    -a "(find ~/.config/.glasveil-backups -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null; echo latest)" \
    -d "备份标签"

complete -c install.sh -l copy      -d "部署时复制而不是软链"
complete -c install.sh -l link      -d "部署时软链（默认）"
complete -c install.sh -l dry-run   -d "只打印，不落地"
complete -c install.sh -l yes       -s y -d "跳过确认"
complete -c install.sh -l repo-only -d "只装仓库包，跳过 AUR"
complete -c install.sh -l help      -s h -d "显示帮助"
