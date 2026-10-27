#compdef install.sh
# zsh completion for Glasveil install.sh
# 用法: 放进 $fpath 里并执行 compinit
_install.sh() {
    local -a cmds opts backups
    cmds=(
        'deploy:只部署配置到 ~/.config'
        'deps:只安装依赖（仓库包 + AUR）'
        'all:先装依赖再部署'
        'backup:备份当前配置'
        'restore:回滚到某个备份'
        'list-backups:列出已有备份'
        'completion:输出 shell 补全脚本'
        'help:显示帮助'
    )
    opts=(
        '--copy:部署时复制而不是软链'
        '--link:部署时软链（默认）'
        '--dry-run:只打印，不落地'
        '--yes:跳过确认'
        '--repo-only:只装仓库包，跳过 AUR'
        '--help:显示帮助'
    )
    if [[ $words[CURRENT-1] == restore ]]; then
        backups=(${(f)"$(find ${XDG_CONFIG_HOME:-$HOME/.config}/.glasveil-backups -mindepth 1 -maxdepth 1 -type d -t 2>/dev/null | xargs -r -n1 basename)"} latest)
        _describe 'backup' backups
        return
    fi
    if [[ $words[CURRENT-1] == completion ]]; then
        _values 'shell' bash fish zsh
        return
    fi
    if [[ $words[CURRENT] == -* ]]; then
        _describe 'option' opts
    else
        _describe 'command' cmds
    fi
}
_install.sh "$@"
