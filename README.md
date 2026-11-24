<div align="center">

# Glasveil

**/ˈɡlæsveɪl/** · 一套 Material You 风格的 [niri](https://github.com/YaLteR/niri) 桌面配置<br />
<sub>玻璃感窗口 · 壁纸取色 · 浮动星环启动器 · eww 胶囊状态栏</sub>

</div>

---

## 特性

- **壁纸驱动配色**：`matugen` 从当前壁纸取 Material You 调色板，一次生成 niri / kitty / GTK / fcitx5 / eww / **rofi** / fastfetch / wifitui / **zed** / yazi / starship / btop / cava / hyprlock … 全部配色
- **明暗一键切换**（`Mod+Shift+N`）：整套配色 + GTK 主题 + 终端 + 输入法一起切
- **视频壁纸**：`wallpaper-apply.sh` 按 MIME 分流 —— 视频交给 `mpvpaper`（`loop-file=inf` + `panscan=1.0` 等比铺满），静态图仍走 `awww`；两者互斥切换，取色统一用 ffmpeg 抠首帧
- **rofi 接管外壳**：`Mod+R` 启动器（drun）/ `Mod+V` 剪贴板历史（clipse → rofi → `wl-copy`）/ `Mod+W` 壁纸选择器 / `Mod+Shift+G` 壁纸画廊
- **壁纸选择器**（`Mod+W`）：全屏九条竖版卡片、零控件，底图连同 9 个条位的投影由 `tools/make-picker-bg.py` 预先烤进 JPEG；选中只有 2px 薄荷描边
- **玻璃质感**：窗口 90% 不透明度 + 真实背景模糊，`effects.kdl` 软链一换即可在「普通 / 护眼」间切换
- **护眼模式**（`Mod+N`）：关模糊（含 eww / rofi 的 layer 面）、透明度加重、5500K 暖色温
- **指针键位层**（`Alt+H/J/K/L`）：用 `ydotool` 把指针移动、左右键（`Alt+S` / `Alt+X`）、滚动（`Alt+,` / `Alt+.`）绑到键盘，纯键盘也能点界面
- **Orbit 星环启动器**（`Mod+Shift+A`）：矢量圆环 + 搜索轮盘 + 应用/网页子菜单
- **Sweep 缓存清理**（星环菜单内）：带勾选 UI、干跑模式、白名单围栏（绝不碰 `$HOME` 本身）
- **eww 胶囊状态栏**：透明底 + 胶囊模块，跟随配色；工作区按输出序号取，单屏 / 插拔屏都不错位
- **电池保护**：开机把充电阈值锁在 80%（需一次性 root 配置，见 `configs/niri/README-battery.md`）

## 壁纸选择器主题（rofi）

`configs/rofi/wallpaper.rasi` 是从一张效果图逐像素还原的：全屏 9 条竖版卡片，
没有搜索框 / 按钮 / 滑杆，选中项只加一圈 2px 薄荷描边 `rgba(150,255,210,0.75)`。

底图 `configs/rofi/assets/picker-bg.jpg`（2240×1362）由 `tools/make-picker-bg.py` 生成：
渐变 + 中心辉光 + 流线 + 颗粒照抄效果图，并把 9 个条位的**投影**一起烤进去，
顶部裁掉 38px（eww 状态栏的 exclusive zone）后与 rofi 的 layer 面 1:1 对齐。
存 JPEG 是因为颗粒让 PNG 压不动（2.3MB → 278KB）。

rofi 2.1 的几个坑（改参数前必读，`wallpaper.rasi` 头部注释里有完整推导）：

| 现象 | 做法 |
|---|---|
| 竖图被塞进正方形 | `element-icon` 的 `size` 是**框**的边长，必须 `squared: false`（此处 680） |
| 9 条排成了 9 行 | `layout: horizontal` 时两轴互换：`columns: 1`（行数）+ `lines: 9`（每行条数） |
| 整排比屏幕宽 | `mainbox` 用负左右 padding `-57.5px` 做居中出血，超出的条被窗口自然裁掉 |
| 间距总差 1px | rofi 把逻辑像素取整：`spacing: 27.5px` 实际按 27 排版 |
| 透明值变白 | `element` 背景上的 rgba **变量**会回退成白色，必须写字面量 |

单位换算：本机 `2240×1400 @ scale 1.2`，物理 ÷ 1.2 = rofi 的逻辑像素（231 → 192.5，816 → 680）。

## 目录结构

```
Glasveil/
├── README.md / README.zh-CN.md
├── LICENSE                     # GPL-3.0
├── CREDITS.md                  # 派生自 Nyxuri 的部分署名
├── install.sh                  # 最小部署脚本（备份 + 链接/复制）
├── assets/                     # 截图等
├── tools/                      # 一次性生成脚本（make-picker-bg、效果图 mockup）
└── configs/
    ├── niri/                   # 合成器配置：kdl + scripts/ + tools/ + __presets__/
    ├── kitty/                  # 终端
    ├── fish/                   # shell
    ├── eww/                    # 状态栏
    ├── matugen/                # 取色模板与脚本（配色管线核心）
    ├── fastfetch/              # 系统信息
    ├── wifitui/                # （模板在 matugen/templates/wifitui-theme.toml）
    ├── zed/  # 主题由 matugen 生成（Glasveil Dark / Light）
    ├── rofi/                   # 启动器 / 剪贴板 / 壁纸选择器（含 assets/picker-bg.jpg）
    ├── yazi/ · wireplumber/ · xdg-desktop-portal/
    └── scripts/                # 共享脚本（matugen-update、wallpaper-apply/frame/post）
```

每个 `configs/<app>/` 下的 `.module.toml` 描述该应用需要的包、需要跨更新保留的文件
（`__custom__` 命名约定同样适用）。

## 快捷键（节选）

| 键 | 动作 |
|---|---|
| `Mod+Return` / `Mod+E` / `Mod+R` | 终端 / 文件管理器 / rofi 启动器 |
| `Mod+V` / `Mod+W` | rofi 剪贴板历史 / rofi 壁纸选择器（九条竖版卡片） |
| `Mod+Shift+G` / `Mod+Ctrl+W` | 壁纸画廊（浏览器网格）/ 随机壁纸 |
| `Mod+Z C J K`（含 `Mod+←→↑↓`） | 焦点移动，浮动窗口内外自动贯通 |
| `Mod+T` / `Mod+Shift+T` | 窗口浮动切换 / 悬浮与平铺之间切焦点 |
| `Mod+N` / `Mod+Shift+N` | 护眼模式 / 明暗切换 |
| `Mod+Shift+A` | Orbit 星环（`2` → System Tools → `1` Sweep 清理缓存） |
| `Mod+Shift+S` / `Mod+P` | 区域截图标注 / 全屏截图 |
| `Mod+1..9` / `Mod+Shift+1..9` | 切换工作区 / 把列移到工作区 |
| `Alt+H/J/K/L` | 指针移动（`ydotool`，每格 25px） |
| `Alt+S` / `Alt+X` | 鼠标左键 / 右键 |
| `Alt+,` / `Alt+.` | 滚轮下滚 / 上滚 |

完整键位见 `configs/niri/binds.kdl`，rofi 相关的个人绑定在 `configs/niri/__custom__.kdl`，
或按 `Mod+/` 看内置提示（`Mod+Tab` 是 overview）。

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

`configs/scripts/matugen-update.sh` 会随 `deploy` 链到 `~/.local/bin/matugen-update`
（waypaper 的 `post_command` 用这个路径）；`deploy` / `backup` / `restore` 都覆盖这一项，
仓库根目录的 `bin/` 已取消，统一从 `configs/scripts/` 软链。

### Shell 补全

```bash
./install.sh completion fish   # 输出 fish 补全脚本
./install.sh completion bash   # 输出 bash 补全脚本
./install.sh completion zsh    # 输出 zsh 补全脚本
```

- **fish**：`cp configs/fish/completions/install.sh.fish ~/.config/fish/completions/`，或在 `config.fish` 里
  `source ~/Glasveil/configs/fish/completions/install.sh.fish`
- **bash**：`source configs/fish/completions/install.sh.bash`
- **zsh**：把 `configs/fish/completions/_install.sh` 放进 `$fpath` 任意目录后 `compinit`

补全内容：子命令、选项，以及 `restore <TAB>` 会列出 `~/.config/.glasveil-backups/` 里真实的备份标签。

依赖（Arch）：`niri matugen kitty fish eww rofi imagemagick fcitx5-gtk wifitui starship yazi`
+ AUR/可选：`gtk-layer-shell python-gobject python-cairo`（Orbit 星环）、`swayidle`、`awww`、
`mpvpaper`（视频壁纸）、`clipse`（剪贴板历史来源）

配色管线：壁纸 → `wallpaper-apply.sh`（视频 → `mpvpaper`，图片 → `awww`）→
`wallpaper-post.sh`（写回 waypaper 的 `config.ini` 并跑它的 `post_command`）→
`matugen-update` → 全部主题文件；视频 / 动图先取首帧再取色。

## 版本

版本号**由 git 标签决定**，`./install.sh version` 打印：

| git 状态 | 输出 |
|---|---|
| HEAD 正好在 `v1.3` | `1.3` |
| tag 之后还有 5 个提交 | `1.3+5` |
| 另有未提交改动 | `1.3+5-dirty` |

发布流程：改 `CHANGELOG.md` → `git commit` → `git tag -a vX.Y.Z -m "..."` → `git push && git push --tags`。
递增规则：**MAJOR** 需要迁移的配置结构变化 · **MINOR** 新增功能/配色模板 · **PATCH** 修复。

## 许可

GPL-3.0。派生自 [Nyxuri](https://github.com/ech678/Nyxuri) 的部分同样为 GPL-3.0，
详见 [CREDITS.md](CREDITS.md)。
