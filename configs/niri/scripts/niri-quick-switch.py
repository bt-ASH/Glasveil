#!/usr/bin/env python3

import subprocess
import json
import sys
import shutil
import time  # <--- 新增：用于等待窗口关闭生效

# ================= Configuration =================
EXCLUDE_APPS = ["rofi", "quick-switch", "niri-quick-switch"]
ROFI_ARGS = [
    "-dmenu",
    "-i",
    "-show-icons",
    "-p", "Switch: ",
    "-mesg", "Enter: 切换 / Ctrl+H: 关闭",
    "-kb-custom-1", "Ctrl+h",
]
# =================================================

def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0: return None
        if "-j" in cmd:
            return json.loads(result.stdout)
        return result.stdout
    except Exception: return None

def get_active_output_workspace_ids():
    """
    获取当前活动显示器（output）上的所有工作区 ID
    """
    workspaces = run_cmd("niri msg -j workspaces")
    if not workspaces: return set()
    
    # 1. 找到当前聚焦的工作区所在的显示器名称
    active_output = None
    for ws in workspaces:
        if ws.get("is_focused"):
            active_output = ws.get("output")
            break
            
    if not active_output: return set()
    
    # 2. 收集该显示器上的所有工作区 ID
    valid_ws_ids = set()
    for ws in workspaces:
        if ws.get("output") == active_output:
            valid_ws_ids.add(ws.get("id"))
            
    return valid_ws_ids

def get_window_sort_key(w):
    # 将 workspace_id 作为第一排序优先级，确保不同工作区的窗口按组排列
    ws_id = w.get("workspace_id", 0)
    
    if w.get("is_floating"):
        return (ws_id, 99999, 0, w.get("id"))
    try:
        layout = w.get("layout", {})
        if not layout: return (ws_id, 9999, 0, w.get("id"))
        pos = layout.get("pos_in_scrolling_layout")
        if pos and isinstance(pos, list) and len(pos) >= 2:
            return (ws_id, pos[0], pos[1], w.get("id"))
    except Exception:
        pass
    return (ws_id, 9999, 0, w.get("id"))

def rofi_line(w):
    """与输入列表完全一致的显示文本，用于把 rofi 的输出映射回窗口。"""
    app_id = w.get("app_id") or "Wayland"
    title = (w.get("title") or "No Title").replace("\n", " ")
    return f"[{app_id}] {title}"


def main():
    if not shutil.which("rofi"):
        print("Error: rofi not found")
        sys.exit(1)

    # === 核心改动：开启死循环 ===
    while True:
        # 1. 每次循环重新获取当前显示器上的所有 Workspace ID
        valid_ws_ids = get_active_output_workspace_ids()
        if not valid_ws_ids: break

        # 2. 每次循环都重新获取最新的窗口列表
        windows = run_cmd("niri msg -j windows")
        if not windows: break

        current_windows = []
        for w in windows:
            # 判断窗口是否在允许的工作区集合内
            if w.get("workspace_id") not in valid_ws_ids: continue
            app_id = w.get("app_id") or ""
            if app_id in EXCLUDE_APPS: continue
            current_windows.append(w)

        # 如果没有窗口了，直接退出
        if not current_windows: break

        current_windows.sort(key=get_window_sort_key)

        input_str = ""
        for w in current_windows:
            app_id = w.get("app_id") or "Wayland"
            line = f"{rofi_line(w)}\0icon\x1f{app_id}"
            input_str += f"{line}\n"

        try:
            # 3. 启动 rofi
            proc = subprocess.Popen(
                ["rofi"] + ROFI_ARGS,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                text=True
            )
            stdout, _ = proc.communicate(input=input_str)
            
            return_code = proc.returncode
            raw_output = stdout.strip()

            # 情况 A: 用户按 ESC / 取消 -> 退出循环
            if return_code not in (0, 10) or not raw_output:
                break

            # rofi 返回选中行的文本（过滤后行号不可靠），按文本找回窗口
            target_window = next(
                (w for w in current_windows if rofi_line(w) == raw_output), None
            )
            if target_window is None:
                break

            target_id = target_window.get("id")

            if return_code == 0:
                # 动作: 切换窗口 -> 任务完成，退出循环
                subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(target_id)])
                break
            else:
                # 动作: 关闭窗口（Ctrl+H 自定义键）-> 执行关闭，然后继续循环
                subprocess.run(["niri", "msg", "action", "close-window", "--id", str(target_id)])
                # 稍等，让 niri 处理关闭，避免刷新列表时又看到该窗口
                time.sleep(0.1)
                continue

        except Exception as e:
            print(f"Error: {e}")
            break

if __name__ == "__main__":
    main()
