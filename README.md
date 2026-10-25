<div align="center">

# Glasveil

**/ˈɡlæsveɪl/** · 一套 Material You 风格的 [niri](https://github.com/YaLteR/niri) 桌面配置<br />
<sub>玻璃感窗口 · 壁纸取色 · 浮动星环启动器 · eww 胶囊状态栏</sub>

</div>

---

## 特性

- **壁纸驱动配色**：`matugen` 从当前壁纸取 Material You 调色板，一次生成 niri / kitty / GTK / fcitx5 / eww / fastfetch / wifitui / yazi / starship / btop / cava … 全部配色
- **明暗一键切换**（`Mod+Shift+N`）：整套配色 + GTK 主题 + 终端 + 输入法一起切
- **玻璃质感**：窗口 90% 不透明度 + 真实背景模糊，`effects.kdl` 软链一换即可在「普通 / 护眼」间切换
- **护眼模式**（`Mod+N`）：关模糊、透明度加重、5500K 暖色温
- **Orbit 星环启动器**（`Mod+Shift+A`）：矢量圆环 + 搜索轮盘 + 应用/网页子菜单
- **Sweep 缓存清理**（星环菜单内）：带勾选 UI、干跑模式、白名单围栏（绝不碰 `$HOME` 本身）
- **eww 胶囊状态栏**：透明底 + 胶囊模块，跟随配色；工作区选中态用 primary 淡染
- **电池保护**：开机把充电阈值锁在 80%（需一次性 root 配置，见 `configs/niri/README-battery.md`）

## 目录结构

```
Glasveil/
├── README.md / README.zh-CN.md
├── LICENSE                     # GPL-3.0
├── CREDITS.md                  # 派生自 Nyxuri 的部分署名
├── install.sh                  # 最小部署脚本（备份 + 链接/复制）
├── assets/                     # 截图等
└── configs/
    ├── niri/                   # 合成器配置：kdl + scripts/ + tools/ + __presets__/
    ├── kitty/                  # 终端
    ├── fish/                   # shell
    ├── eww/                    # 状态栏
    ├── matugen/                # 取色模板与脚本（配色管线核心）
    ├── fastfetch/              # 系统信息
    ├── wifitui/                # （模板在 matugen/templates/wifitui-theme.toml）
    ├── yazi/ · wireplumber/ · xdg-desktop-portal/
    └── scripts/                # 共享脚本（matugen-update 等）
```

每个 `configs/<app>/` 下的 `.module.toml` 描述该应用需要的包、需要跨更新保留的文件
（`__custom__` 命名约定同样适用）。

## 快捷键（节选）

| 键 | 动作 |
|---|---|
| `Mod+Return` / `Mod+E` / `Mod+R` | 终端 / 文件管理器 / 启动器 |
| `Mod+Z C J K`（含 `Mod+←→↑↓`） | 焦点移动，浮动窗口内外自动贯通 |
| `Mod+T` / `Mod+Shift+T` | 窗口浮动切换 / 悬浮与平铺之间切焦点 |
| `Mod+W` / `Mod+Ctrl+W` | 壁纸选择 / 随机壁纸 |
| `Mod+N` / `Mod+Shift+N` | 护眼模式 / 明暗切换 |
| `Mod+Shift+A` | Orbit 星环（`2` → System Tools → `1` Sweep 清理缓存） |
| `Mod+Shift+S` / `Mod+P` | 区域截图标注 / 全屏截图 |
| `Mod+1..9` / `Mod+Shift+1..9` | 切换工作区 / 把列移到工作区 |

完整键位见 `configs/niri/binds.kdl`，或按 `Mod+/` 看内置提示。

## 安装

```bash
git clone <this-repo> ~/Glasveil
cd ~/Glasveil
./install.sh                 # 交互菜单（1 部署 / 2 依赖 / 3 两者 / 4 备份 / 5 回滚 / 6 列备份）
./install.sh deploy          # 只部署配置（默认；--copy 复制模式，--dry-run 预演）
./install.sh deps            # 只安装依赖（仓库包 + AUR 包；--repo-only 跳过 AUR）
./install.sh all             # 先装依赖再部署
./install.sh backup 调参前    # 打快照
./install.sh list-backups    # 列出备份
./install.sh restore latest  # 回滚到最近一次
```

依赖（Arch）：`niri matugen kitty fish eww fcitx5-gtk wifitui starship yazi`
+ AUR/可选：`gtk-layer-shell python-gobject python-cairo`（Orbit 星环）、`swayidle`、`awww`

配色管线：壁纸 → `matugen-update`（waypaper 的 `post_command` 自动调用）→ 全部主题文件。

## 许可

GPL-3.0。派生自 [Nyxuri](https://github.com/ech678/Nyxuri) 的部分同样为 GPL-3.0，
详见 [CREDITS.md](CREDITS.md)。
