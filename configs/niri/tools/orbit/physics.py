"""
Orbit Launcher Physics Engine
Analytical second-order spring solver (exact for a constant target).

x'' = -w^2 (x - target) - 2 zeta w x'

为什么必须是解析解：
原来的显式欧拉积分在「帧间隔大」时会发散 —— 例如在 2240x1400 @1.2 缩放下
单帧要 100ms+（dt 被钳到 0.05），欧拉步长 x''*dt 会过冲，core 弹簧在
±270px 之间剧烈摆动，跟随光标的虚线于是疯狂抽搐；而在 1366x768（60fps，
dt≈0.016）下欧拉是稳定的，所以小分辨率看起来正常。

解析解对任意 dt 都无条件稳定，并且带 settle 吸附，静止后不再重绘。
"""

import math

SETTLE_POS = 0.08   # 逻辑像素（亚像素级，肉眼不可见）
SETTLE_VEL = 3.0    # 像素/秒


class Spring:
    """Analytical spring: exact integration for a constant target, stable for any dt."""

    def __init__(self, initial: float = 0.0, omega: float = 14.0, zeta: float = 0.70):
        self.current = initial
        self.target = initial
        self.velocity = 0.0
        self.omega = omega
        self.zeta = zeta

    def update(self, dt: float) -> bool:
        dt = min(0.25, max(0.0005, dt))

        if abs(self.current - self.target) < SETTLE_POS and abs(self.velocity) < SETTLE_VEL:
            self.current = self.target
            self.velocity = 0.0
            return False

        w = max(0.01, self.omega)
        z = min(0.999, max(0.0, self.zeta))     # 限制在欠阻尼区间，保证解析式有效
        wd = w * math.sqrt(1.0 - z * z)

        x0 = self.current - self.target
        v0 = self.velocity
        e = math.exp(-z * w * dt)
        c = math.cos(wd * dt)
        s = math.sin(wd * dt)

        a = x0
        b = (v0 + z * w * x0) / wd
        self.current = self.target + e * (a * c + b * s)
        self.velocity = e * ((-z * w * a + wd * b) * c + (-z * w * b - wd * a) * s)

        if abs(self.current - self.target) < SETTLE_POS and abs(self.velocity) < SETTLE_VEL:
            self.current = self.target
            self.velocity = 0.0
            return False
        return True
