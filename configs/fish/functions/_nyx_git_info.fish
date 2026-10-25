function _nyx_git_info --description "在 git 仓库里输出 ' git图标 分支名'，不在仓库里输出空"
    # 与 starship 的 git_branch 一致：在仓库的子目录里也算（会向上查找）。
    # 分支名取不到时退回头哈希；两者都取不到就只显示图标。
    command git rev-parse --git-dir &>/dev/null; or return

    set -l b (command git branch --show-current 2>/dev/null | string collect)
    if test -z "$b"
        set b (command git rev-parse --short HEAD 2>/dev/null | string collect)
    end

    if test -n "$b"
        printf '\ue702 %s' $b
    else
        printf '\ue702'
    end
end
