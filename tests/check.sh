#!/usr/bin/env bash
# Glasveil 静态检查：语法、TOML 合法性、niri 配置校验
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
fail=0

say() { printf '\n== %s\n' "$1"; }
ok()  { printf '  \033[32mOK\033[0m %s\n' "$1"; }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=1; }

say "shell 脚本语法"
while IFS= read -r -d '' f; do
    if bash -n "$f" 2>/dev/null; then ok "$f"; else bad "$f"; fi
done < <(find configs -name '*.sh' -print0)

say "python 语法"
while IFS= read -r -d '' f; do
    if python3 -m py_compile "$f" 2>/dev/null; then ok "$f"; else bad "$f"; fi
done < <(find configs -name '*.py' -not -path '*/__pycache__/*' -print0)

say "TOML 合法性"
python3 - <<'PY' || exit 1
import sys, tomllib, pathlib
bad = 0
for p in pathlib.Path("configs").rglob("*.toml"):
    try:
        tomllib.loads(p.read_text(encoding="utf-8"))
        print(f"  \033[32mOK\033[0m {p}")
    except Exception as e:
        print(f"  \033[31mFAIL\033[0m {p}: {e}")
        bad = 1
sys.exit(bad)
PY
[ $? -ne 0 ] && fail=1

say "niri 配置校验（未安装 niri 则跳过）"
if command -v niri >/dev/null 2>&1; then
    if niri validate -c configs/niri/config.kdl >/dev/null 2>&1; then
        ok "configs/niri/config.kdl"
    else
        bad "configs/niri/config.kdl"
    fi
else
    echo "  (skipped: niri not installed)"
fi

printf '\n'
if [ "$fail" = 0 ]; then echo "全部检查通过 ✅"; else echo "存在失败项 ❌"; fi
exit "$fail"
