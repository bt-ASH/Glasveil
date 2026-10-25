function _nyx_pill --description "画一个药丸胶囊：_nyx_pill <底色> <字色> <内容>"
    set -l bg $argv[1]
    set -l fg $argv[2]
    set -l txt $argv[3]

    # 左圆帽（仅前景色，背景保持终端默认）
    set_color normal
    set_color $bg
    printf '\ue0b6'

    # 药丸主体
    set_color -b $bg $fg
    printf ' %s ' $txt

    # 右圆帽
    set_color normal
    set_color $bg
    printf '\ue0b4'

    set_color normal
end
