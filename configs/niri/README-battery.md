# 电池保护 (Battery Care)

`scripts/battery-care.sh` 由 niri 的 `spawn-at-startup` 调用，负责把充电阈值锁在
`start=75% / end=80%`（可用环境变量 `BAT_START` / `BAT_END` 覆盖）。

## 为什么还要一步 root 设置

`/sys/class/power_supply/BAT1/charge_control_end_threshold` 默认是 `root:root 0644`，
普通用户（即使属于 `wheel`）无法写入。脚本按三级降级：

1. 直接写入（如果 udev 给了组写权限）
2. `sudo -n`（免密 sudo）
3. 都没有 → 只写 `$XDG_RUNTIME_DIR/niri-battery-care.log`，静默退出、不阻塞登录

如果阈值已经是目标值，脚本**完全不写**，所以正常登录不会产生失败日志。

## 一次性 root 设置（任选其一）

### 方案 A：systemd-tmpfiles（推荐，开机自动生效）

```bash
sudo tee /etc/tmpfiles.d/battery-threshold.conf <<'CONF'
# Type Path Mode UID GID Age Argument
w /sys/class/power_supply/BAT1/charge_control_end_threshold - - - - 80
w /sys/class/power_supply/BAT1/charge_control_start_threshold - - - - 75
CONF
sudo systemd-tmpfiles --create /etc/tmpfiles.d/battery-threshold.conf
```

### 方案 B：udev 规则 + 组写权限（让 niri 启动项自己写）

```bash
sudo tee /etc/udev/rules.d/99-battery-threshold.rules <<'RULE'
ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", \
  RUN+="/bin/sh -c 'echo 80 > /sys/class/power_supply/%k/charge_control_end_threshold; echo 75 > /sys/class/power_supply/%k/charge_control_start_threshold'"
RULE
sudo udevadm control --reload-rules
```

## 查看状态

```bash
~/.config/niri/scripts/battery-care.sh --status
cat /sys/class/power_supply/BAT1/charge_control_end_threshold
```
