function _nyx_ver --description "_nyx_ver <类型>：返回该工具链版本号；会话内缓存，避免每次提示符都启动进程"
    set -l key _nyx_ver_$argv[1]
    if set -q $key
        printf '%s' $$key
        return
    end

    set -l raw
    switch $argv[1]
        case python
            set raw (python3 --version 2>/dev/null | string collect)
        case nodejs
            set raw (node --version 2>/dev/null | string collect)
        case rust
            set raw (rustc --version 2>/dev/null | string collect)
        case java
            set raw (java -version 2>&1 | string collect)
        case c
            set raw (cc --version 2>/dev/null | string collect)
    end

    # 从原始输出里抽出第一段 x.y[.z...] 版本号
    set -l v (string match -r -- '[0-9]+(\.[0-9]+)+' $raw | head -1)
    set -g $key "$v"
    printf '%s' "$v"
end
