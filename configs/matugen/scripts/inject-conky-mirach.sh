#!/bin/bash

NEW_COLORS="$HOME/.cache/matugen/mirach-colors.conf"
CONKY_CONFIG="$HOME/.config/conky/Mirach/Mirach.conf"

[ -f "$NEW_COLORS" ] || exit 0

cp "$CONKY_CONFIG" "$CONKY_CONFIG.bak"

python3 << EOF
with open('$NEW_COLORS') as f:
    new_block = f.read().strip('\n')

with open('$CONKY_CONFIG') as f:
    content = f.read()

import re
result = re.sub(
    r'-- Color Settings --.*?(?=\n-- Window Settings --)',
    '-- Color Settings --\n' + new_block + '\n',
    content,
    count=1,
    flags=re.DOTALL
)

with open('$CONKY_CONFIG', 'w') as f:
    f.write(result)
EOF

exit 0
