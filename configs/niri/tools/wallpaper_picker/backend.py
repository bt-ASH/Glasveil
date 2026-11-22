"""
Glasveil 壁纸选择器后端
统一切换壁纸到 awww（仅静图，无视频壁纸）。
"""

import os
import shutil
import subprocess
import sys


def _matugen_updater() -> str:
    """返回 matugen 刷新脚本路径（与 waypaper 的 post_command 用同一个）。"""
    for p in ("~/.local/bin/matugen-update", "~/.config/scripts/matugen-update.sh"):
        full = os.path.expanduser(p)
        if os.access(full, os.X_OK):
            return full
    return ""


def apply_static_wallpaper(path: str) -> bool:
    """通过 awww 设置壁纸，并异步刷新 matugen 配色。"""
    if not os.path.isfile(path):
        print(f"Error: wallpaper not found: {path}", file=sys.stderr)
        return False
    if not shutil.which("awww"):
        print("Error: awww not found in PATH", file=sys.stderr)
        return False

    try:
        res = subprocess.run(
            ["awww", "img", path],
            stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=20,
        )
        if res.returncode != 0:
            err = (res.stderr or b"").decode("utf-8", "replace").strip()
            print(f"Error: awww img failed (exit {res.returncode}): {err}", file=sys.stderr)
            return False
    except Exception as e:
        print(f"Error applying wallpaper: {e}", file=sys.stderr)
        return False

    updater = _matugen_updater()
    if updater:
        try:
            subprocess.Popen(
                [updater], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except Exception as e:
            print(f"Warning: matugen refresh failed to start: {e}", file=sys.stderr)
    return True


def apply_wallpaper(item) -> bool:
    """统一入口：所有壁纸都交给 awww。"""
    return apply_static_wallpaper(item.path)
