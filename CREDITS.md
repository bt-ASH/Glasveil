# Credits

Glasveil 是个人 niri 桌面配置，其中一部分组件派生自以下项目，特此署名。

## Nyxuri — https://github.com/ech678/Nyxuri

以 **GPL-3.0** 授权。以下文件派生自 Nyxuri（已按本仓库需要做过修改）：

| 本仓库路径 | 来源 |
|---|---|
| `configs/niri/tools/orbit*`、`configs/niri/tools/orbit-items__custom__.toml` | Nyxuri Orbit 星环启动器 |
| `configs/niri/tools/wallpaper-picker.py`、`configs/niri/tools/wallpaper_picker/` | Nyxuri M3E 壁纸选择器 |
| `configs/niri/scripts/clean-cache.py` | `nyxuri/clean.py` |
| `configs/niri/scripts/toggle-eyecare.sh`、`session` 相关脚本 | `configs/niri/scripts/` |
| `configs/niri/scripts/niri-brightness.sh`（思路：内屏 sysfs + 外屏 DDC 分流） | `configs/niri/scripts/niri-brightness.sh` |
| `configs/niri/scripts/shell-action.sh`、`niri-scratch-toggle.sh` | 同上 |
| `configs/niri/{layout,glow,animations,rules,effects_*}.kdl` 的部分结构 | `configs/niri/` |
| `configs/matugen/templates/{niri-colors.kdl,kitty-override.conf,palette.toml,fcitx5-nyxmellow/*}` | Nyxuri 的配色模板 / NyxMellow 皮肤素材 |
| `configs/fish/` 的骨架 | `configs/fish/` |

其余（niri 键位与规则整理、eww 状态栏、matugen 模板与脚本、主题切换、电池保护、
各 kdl 的中文化与调参等）为本项目原创，同样以 GPL-3.0 发布。

## 其他

- [niri](https://github.com/YaLteR/niri) — 滚动平铺合成器
- [matugen](https://github.com/Iniox/matugen) — Material You 配色生成
- [eww](https://github.com/elkowar/eww) — 状态栏
- [fcitx5](https://github.com/fcitx/fcitx5) — 输入法，NyxtMellow 皮肤素材来自 Nyxuri
- [wifitui](https://github.com/shazow/wifitui) — TUI 无线网络管理（本仓库只提供配色模板）
