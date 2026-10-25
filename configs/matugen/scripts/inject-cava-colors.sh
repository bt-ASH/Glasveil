#!/bin/bash
# 用 matugen 渲染好的颜色替换 ~/.config/cava/config 中的 [color] 块

NEW_COLORS="$HOME/.cache/matugen/cava-colors.ini"
CAVA_CONFIG="$HOME/.config/cava/config"

# 如果颜色文件不存在，退出
[ -f "$NEW_COLORS" ] || exit 0

# 备份原配置
cp "$CAVA_CONFIG" "$CAVA_CONFIG.bak"

# 用 python3 替换 [color] 块
python3 << EOF
with open('$NEW_COLORS') as f:
    new_block = f.read().strip()

with open('$CAVA_CONFIG') as f:
    content = f.read()

import re
# 替换 [color] 行到下一个 [section] 行之前的内容
result = re.sub(
    r'\[color\].*?(?=\n\[|\Z)',
    new_block,
    content,
    count=1,
    flags=re.DOTALL
)

with open('$CAVA_CONFIG', 'w') as f:
    f.write(result)
EOF

# 通知 cava 重载配置（如果正在运行）
pkill -USR1 cava 2>/dev/null

exit 0
