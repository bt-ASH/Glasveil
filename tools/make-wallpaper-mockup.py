#!/usr/bin/env python3
"""壁纸预览效果图：一排 960×3399 竖条壁纸 + 深绿渐变/绿色流线背景，无任何 UI 元素。

几何（逐像素量自参考图 Screenshot-1789814347-398.png，2240×1400）：
  · 每张壁纸展示 231×816 px，原图 960×3399（比例一致）
  · 条间距 37 px，整排水平居中、顶边与参考图同为 y=179，首尾出血到画布外
  · 画面下方只有渐变背景，没有任何控件 / 文字 / 搜索框 / 滑块
"""
from __future__ import annotations

import math
import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 2240, 1400                  # 成图尺寸（与参考图一致）
CANVAS_STRIP = (960, 3399)         # 每条壁纸的原始尺寸（9:21 类竖长）
STRIP_W, STRIP_H = 231, 816        # 参考图中的展示尺寸
GAP = 37                           # 参考图中的竖条间距
TOP = 179                          # 参考图中竖条顶边的位置（整排水平居中）
COUNT = math.ceil((W + GAP) / (STRIP_W + GAP))      # 两侧出血，铺满整宽

SRC_DIR = pathlib.Path("/home/ash/Pictures/Wallpapers")
OUT = pathlib.Path("/home/ash/Pictures/mockup-wallpaper-strips.png")

# 按「深/浅」交替排布，和参考图一样有明暗节奏
SOURCES = [
    "black-white-girl.png",
    "孤独摇滚-波奇酱.png",
    "wallhaven-qr2wd5.png",
    "【哲风壁纸】少女-鸣潮.jpg",
    "【哲风壁纸】二次元角色-动漫.png",
    "【哲风壁纸】弗洛洛-红衣-花瓣.jpg",
    "【哲风壁纸】少女-校园背景.png",
    "NIKK姬野.webp",
    "报纸墙前-少女.png",
]


def _smoothstep(a: float, b: float, v: np.ndarray) -> np.ndarray:
    t = np.clip((v - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# ── 1. 背景：深绿渐变 + 柔和流动的绿色流线光效 ─────────────────────────
def background() -> Image.Image:
    y = np.linspace(0.0, 1.0, H, dtype=np.float32)[:, None]
    x = np.linspace(0.0, 1.0, W, dtype=np.float32)[None, :]

    # 深绿竖向渐变（顶部近墨绿，中部稍亮，底部沉下去）
    stops = np.array([0.00, 0.22, 0.48, 0.72, 1.00], np.float32)
    colors = np.array(
        [
            [2, 10, 8],
            [6, 26, 19],
            [9, 44, 32],
            [6, 27, 20],
            [2, 9, 7],
        ],
        np.float32,
    )
    img = np.empty((H, W, 3), np.float32)
    for c in range(3):
        img[..., c] = np.interp(y[:, 0], stops, colors[:, c])[:, None]

    # 竖条后方的柔和绿色辉光（让竖条和背景分离）
    glow = np.exp(-(((x - 0.5) / 0.62) ** 2 + ((y - 0.5) / 0.42) ** 2))
    img += glow[..., None] * np.array([10, 54, 38], np.float32)
    glow2 = np.exp(-(((x - 0.50) / 0.30) ** 2 + ((y - 0.50) / 0.22) ** 2))
    img += glow2[..., None] * np.array([6, 30, 22], np.float32)

    # 柔和的绿色流线：低频长波 + 宽高斯带，叠加成“流动”的丝带
    lights = np.zeros((H, W, 3), np.float32)
    rng = np.random.default_rng(20261123)
    palette = np.array(
        [
            [64, 232, 164],
            [38, 204, 172],
            [88, 246, 196],
            [26, 170, 142],
            [120, 255, 206],
        ],
        np.float32,
    )
    for i in range(17):
        base = rng.uniform(0.04, 1.02)
        slope = rng.uniform(-0.30, 0.30)
        curve = rng.uniform(-0.16, 0.16)
        amp = rng.uniform(0.018, 0.062)
        freq = rng.uniform(0.55, 2.10)
        phase = rng.uniform(0.0, math.tau)
        sigma = rng.uniform(0.005, 0.024)
        power = rng.uniform(0.16, 0.44)
        col = palette[rng.integers(0, len(palette))]
        xa = rng.uniform(-0.25, 0.42)
        xb = rng.uniform(0.58, 1.25)

        cy = (
            base
            + slope * (x - 0.5)
            + curve * (x - 0.5) ** 2
            + amp * np.sin(freq * math.tau * x + phase)
            + 0.5 * amp * np.sin(2.0 * freq * math.tau * x + phase * 1.7)
        )
        sigma_x = sigma * (1.0 + 0.25 * np.sin(1.7 * math.tau * x + phase))
        band = np.exp(-0.5 * ((y - cy) / sigma_x) ** 2)
        band *= _smoothstep(xa, xa + 0.30, x) * (1.0 - _smoothstep(xb - 0.30, xb, x))
        band *= 0.75 + 0.25 * np.sin(1.3 * math.tau * x + phase * 0.6)
        lights += band[..., None] * col * power

    # 几根更细更亮的丝线，顺着同样的走向，做出“流动感”
    for i in range(5):
        base = rng.uniform(0.08, 0.98)
        slope = rng.uniform(-0.26, 0.26)
        amp = rng.uniform(0.02, 0.05)
        freq = rng.uniform(0.7, 1.8)
        phase = rng.uniform(0.0, math.tau)
        cy = (
            base
            + slope * (x - 0.5)
            + amp * np.sin(freq * math.tau * x + phase)
        )
        band = np.exp(-0.5 * ((y - cy) / 0.0028) ** 2)
        band *= _smoothstep(-0.05, 0.45, x) * (1.0 - _smoothstep(0.55, 1.05, x))
        lights += band[..., None] * np.array([150, 255, 210], np.float32) * 0.34

    # 两条更宽、更淡的“雾带”，给流线垫底
    for base, slope, sigma, power, col in [
        (0.30, -0.16, 0.085, 0.14, (26, 150, 118)),
        (0.80, 0.12, 0.100, 0.07, (20, 130, 106)),
    ]:
        cy = base + slope * (x - 0.5) + 0.03 * np.sin(1.1 * math.tau * x + 1.2)
        band = np.exp(-0.5 * ((y - cy) / sigma) ** 2)
        band *= _smoothstep(0.0, 0.35, x) * (1.0 - _smoothstep(0.7, 1.0, x))
        lights += band[..., None] * np.array(col, np.float32) * power

    img += lights

    # 轻微暗角，让中心更聚焦
    vig = 1.0 - 0.42 * (((x - 0.5) * 1.15) ** 2 + ((y - 0.5) * 1.05) ** 2)
    img *= np.clip(vig, 0.42, 1.0)[..., None]

    # 细颗粒抖动，消除大面积渐变的色带
    img += np.random.default_rng(7).normal(0.0, 1.1, (H, W, 1)).astype(np.float32)
    img = np.clip(img, 0, 255).astype(np.uint8)
    return Image.fromarray(img, "RGB").filter(ImageFilter.GaussianBlur(0.6))


# ── 2. 竖条：裁成 960×3399 的竖向切片，再缩到 231×816 ─────────────────
def _saliency_offset(im: Image.Image, crop_w: int) -> int:
    """在横图里找一条信息量最大的竖切片（偏中心权重），避免裁掉主体。"""
    w, h = im.size
    if crop_w >= w:
        return 0
    sw = 320
    small = im.resize((sw, max(1, int(sw * h / w))), Image.BILINEAR)
    a = np.asarray(small, np.float32)
    g = a.mean(2)
    edges = np.abs(np.diff(g, axis=1))
    edges = np.pad(edges, ((0, 0), (0, 1)), mode="edge")
    sat = (a.max(2) - a.min(2)) / (a.max(2) + 1e-3)
    score = 0.62 * edges / (edges.max() + 1e-6) + 0.38 * sat
    col = score.mean(0)
    col = np.convolve(col, np.ones(9) / 9, mode="same")
    win = max(1, int(round(sw * crop_w / w)))
    best = (-1.0, 0)
    for x0 in range(0, sw - win + 1):
        s = float(col[x0 : x0 + win].sum())
        cx = (x0 + win / 2) / sw
        s *= 0.65 + 0.35 * math.exp(-(((cx - 0.5) / 0.34) ** 2))
        if s > best[0]:
            best = (s, x0)
    return min(w - crop_w, int(round(best[1] * w / sw)))


def make_strip(path: pathlib.Path) -> Image.Image:
    im = Image.open(path).convert("RGB")
    w, h = im.size
    target_r = CANVAS_STRIP[0] / CANVAS_STRIP[1]          # 960/3399
    cur_r = w / h
    if cur_r > target_r:                                   # 横图：裁窄
        cw = max(1, int(round(h * target_r)))
        left = _saliency_offset(im, cw)
        im = im.crop((left, 0, left + cw, h))
    elif cur_r < target_r:                                 # 更窄的竖图：裁高
        ch = max(1, int(round(w / target_r)))
        top = (h - ch) // 2
        im = im.crop((0, top, w, top + ch))
    im = im.resize(CANVAS_STRIP, Image.LANCZOS)            # 960×3399
    return im.resize((STRIP_W, STRIP_H), Image.LANCZOS)    # 231×816


# ── 3. 合成：一排竖条居中，底部只有渐变背景 ────────────────────────────
def main() -> None:
    srcs = [SRC_DIR / name for name in SOURCES]
    missing = [str(p) for p in srcs if not p.exists()]
    if missing:
        raise SystemExit("缺少壁纸：" + ", ".join(missing))
    strips = [make_strip(p) for p in srcs]

    pitch = STRIP_W + GAP
    n = COUNT
    total = n * STRIP_W + (n - 1) * GAP
    x0 = round((W - total) / 2)

    canvas = background()

    # 整排柔和投影，让竖条像浮在背景上
    shadow = Image.new("L", (W, H), 0)
    ds = ImageDraw.Draw(shadow)
    for i in range(n):
        x = x0 + i * pitch
        ds.rectangle((x + 2, TOP + 6, x + STRIP_W - 2, TOP + STRIP_H + 12), fill=120)
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    canvas = Image.composite(Image.new("RGB", (W, H), (0, 6, 4)), canvas, shadow)

    for i in range(n):
        x = x0 + i * pitch
        canvas.paste(strips[i % len(strips)], (x, TOP))

    canvas.save(OUT, quality=95)
    print(
        f"已生成 {OUT}  ({W}×{H})  "
        f"竖条 {n} 条 × {STRIP_W}×{STRIP_H}px（960×3399），间距 {GAP}px，"
        f"顶边 top={TOP}px，左起 x={x0}px"
    )


if __name__ == "__main__":
    main()
