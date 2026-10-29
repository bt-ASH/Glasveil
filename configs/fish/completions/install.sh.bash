# bash completion for Glasveil install.sh
# 用法: source ~/Glasveil/configs/fish/completions/install.sh.bash
_glasveil_install() {
    local cur prev cmds opts backups
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmds="deploy deps all backup restore list-backups completion help"
    opts="--copy --link --dry-run --yes --repo-only -h --help"

    case "$prev" in
        restore)
            backups="$(find "${XDG_CONFIG_HOME:-$HOME/.config}/.glasveil-backups" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)"
            COMPREPLY=( $(compgen -W "$backups" -- "$cur") ); return 0 ;;
        completion)
            COMPREPLY=( $(compgen -W "bash fish zsh" -- "$cur") ); return 0 ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") ); return 0
    fi
    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
}
complete -F _glasveil_install install.sh
