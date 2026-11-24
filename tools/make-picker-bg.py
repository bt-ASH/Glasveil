#!/usr/bin/env python3
"""生成 rofi 壁纸选择器的背景底图：效果图的背景 + 竖条投影，但不含竖条本身。

参数全部沿用 ``tools/make-wallpaper-mockup.py``（规格见
``~/Pictures/mockup-wallpaper-strips.md``）：

  · §4 渐变 / 中心辉光 / 17 条流线 / 5 条细丝 / 2 条雾带 / 暗角 / 颗粒
    → 直接复用 ``make-wallpaper-mockup.background()``，不复制实现
  · §5 投影 → 按固定的 9 个条位（x = -68 + 268·i, top = 179）烤进背景，
    这样 rofi 只要把竖条贴在同样的位置，阴影就一定对得上
  · 顶部裁掉 CROP_TOP 行 → 与 rofi 的 layer 面 1:1 对齐

为什么裁顶：eww 状态栏占了屏幕顶部 38 px 的 exclusive zone，niri 给 rofi 的
layer 面就只剩 2240×1362（起点 y=38）。裁掉背景的这 38 行后，背景与 rofi
窗口像素一一对应，竖条顶边仍然落在屏幕坐标 y=179。

重跑：python3 tools/make-picker-bg.py
输出：configs/rofi/assets/picker-bg.jpg  (2240×1362, RGB)

存 JPEG 的原因：§4.6 的高斯颗粒让 PNG 完全压不动（2.3 MiB），JPEG q=93
约 0.3 MiB 且看不出差别（rofi 用 gdk-pixbuf 读图，jpg/png 都行）。
"""
from __future__ import annotations

import importlib.util
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent / "configs" / "rofi" / "assets" / "picker-bg.jpg"
CROP_TOP = 38          # eww 状态栏的 exclusive zone（物理像素）


def _load_mockup():
    """按路径加载 make-wallpaper-mockup.py（文件名带连字符，不能直接 import）。"""
    spec = importlib.util.spec_from_file_location(
        "make_wallpaper_mockup", HERE / "make-wallpaper-mockup.py"
    )
    if spec is None or spec.loader is None:
        raise SystemExit("找不到 make-wallpaper-mockup.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main() -> int:
    m = _load_mockup()
    canvas = m.background()

    # §5 竖条投影：同样的 9 个条位、同样的高斯模糊与合成色
    shadow = Image.new("L", (m.W, m.H), 0)
    draw = ImageDraw.Draw(shadow)
    total = m.COUNT * m.STRIP_W + (m.COUNT - 1) * m.GAP
    x0 = round((m.W - total) / 2)
    for i in range(m.COUNT):
        x = x0 + i * (m.STRIP_W + m.GAP)
        draw.rectangle(
            (x + 2, m.TOP + 6, x + m.STRIP_W - 2, m.TOP + m.STRIP_H + 12),
            fill=120,
        )
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    canvas = Image.composite(Image.new("RGB", (m.W, m.H), (0, 6, 4)), canvas, shadow)

    out = canvas.crop((0, CROP_TOP, m.W, m.H))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out.save(OUT, quality=93, subsampling=0, optimize=True)
    print(
        f"已生成 {OUT}  ({out.width}×{out.height})  "
        f"条位 keep={CROP_TOP}px 裁顶，竖条应贴在窗口 y={m.TOP - CROP_TOP}px"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
