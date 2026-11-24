<div align="center">

# Glasveil

**/ˈɡlæsveɪl/**（玻璃幕）· Material You 风格的 [niri](https://github.com/YaLteR/niri) 桌面配置
<br /><sub>玻璃感窗口 · 壁纸取色 · 浮动星环启动器 · eww 胶囊状态栏</sub>

</div>

## 这是什么

一套自用 niri 配置的完整快照：合成器键位与规则、eww 状态栏、kitty/fish、
matugen 取色模板与脚本，以及几个自己写的小工具（星环启动器入口、缓存清理、
明暗切换、护眼、电池保护、浮动/平铺焦点跳转）。

## 主要特性

- **壁纸取色一条龙**：`matugen` 用 Noctalia 同款 `m3-content` 方案取色，生成
  niri / kitty / GTK3·4 / fcitx5 皮肤 / eww / **rofi** / fastfetch / wifitui / zed / yazi / starship / btop / cava / hyprlock…
- **`Mod+Shift+N` 明暗切换**：重跑 matugen + 切 `gsettings` + 热重载 niri/kitty/fcitx5/eww
- **视频壁纸**：`wallpaper-apply.sh` 按 MIME 分流 —— 视频给 `mpvpaper`（无限循环 + 等比铺满），图片仍走 `awww`；
  两者互斥切换，取色统一用 ffmpeg 抠首帧
- **玻璃质感**：窗口 0.9 不透明度 + `blur passes 3`；`effects.kdl` 软链切换普通/护眼
- **`Mod+N` 护眼**：关模糊（含 eww / rofi 的 layer 面）、透明度加重、`wlsunset` 5500K
- **`Mod+Shift+A` Orbit 星环**：GTK3 + gtk-layer-shell 全屏覆盖层，cairo 矢量绘制
- **rofi 接管外壳**：`Mod+R` 启动器（drun）/ `Mod+V` 剪贴板历史（clipse → rofi → `wl-copy`）/
  `Mod+W` 壁纸选择器 / `Mod+Shift+G` 壁纸画廊，配色由 matugen 渲染
- **`Mod+W` 壁纸选择器**：全屏九条竖版卡片、零控件，选中只加 2px 薄荷描边；
  底图连同 9 个条位的投影由 `tools/make-picker-bg.py` 预先烤进 JPEG，与 rofi 窗口 1:1 对齐
- **指针键位层**：`ydotool` 把 `Alt+H/J/K/L`（移动）、`Alt+S`/`Alt+X`（左右键）、
  `Alt+,`/`Alt+.`（滚动）绑到键盘
- **Sweep 缓存清理**：勾选式 TUI，支持干跑、白名单围栏
- **eww 胶囊状态栏**：透明底、胶囊模块、工作区选中态 primary 淡染
- **电池保护**：开机锁 80% 充电阈值（需一次性 root 配置）

### 壁纸选择器主题里的 rofi 坑

`configs/rofi/wallpaper.rasi` 的头部注释有完整推导，其中三条最容易踩：

- `element-icon` 的 `size` 是**框**的边长，竖图必须配 `squared: false`，否则被塞进正方形；
- `layout: horizontal` 时两轴互换，`columns: 1` 其实是行数、`lines: 9` 才是每行条数；
- `element` 背景上的 rgba **变量**会回退成白色，透明/着色一律写字面量。

## 目录结构

```
Glasveil/
├── configs/
│   ├── niri/        # kdl + scripts/ + tools/ + __presets__/
│   ├── kitty/  fish/  eww/  fastfetch/  matugen/  rofi/
│   ├── yazi/  wireplumber/  xdg-desktop-portal/  scripts/
│   └── starship.toml
├── tools/           # 一次性生成脚本（make-picker-bg、效果图 mockup）
├── install.sh
├── LICENSE (GPL-3.0) · CREDITS.md
└── README.md / README.zh-CN.md
```

## 安装

```bash
git clone <本仓库> ~/Glasveil && cd ~/Glasveil
./install.sh                 # 交互菜单（部署 / 依赖 / 两者 / 备份 / 回滚 / 列备份）
./install.sh deploy          # 只部署配置（默认；--copy 复制，--dry-run 预演）
./install.sh deps            # 只装依赖（仓库包 + AUR；--repo-only 跳过 AUR）
./install.sh all             # 依赖 + 配置
./install.sh backup 调参前    # 快照 / list-backups 列表 / restore latest 回滚
```

## Shell 补全

`./install.sh completion fish|bash|zsh` 输出补全脚本；fish 放到 `~/.config/fish/completions/`，
`restore <TAB>` 会自动列出现有备份标签。

依赖（Arch）：`niri matugen kitty fish eww rofi imagemagick fcitx5-gtk wifitui starship yazi`
+ AUR/可选：`awww`、`mpvpaper`（视频壁纸）、`clipse`（剪贴板历史来源）、
`gtk-layer-shell python-gobject python-cairo`（Orbit 星环）。

配色管线：壁纸 → `wallpaper-apply.sh`（视频 → `mpvpaper`，图片 → `awww`）→
`wallpaper-post.sh`（写回 waypaper 的 `config.ini` 并跑 `post_command`）→ `matugen-update` → 全部主题文件。

`configs/scripts/matugen-update.sh` 会随 `deploy` 额外软链为 `~/.local/bin/matugen-update`
（waypaper 的 `post_command` 用这个路径）；仓库根目录的 `bin/` 已取消。

## 版本

`./install.sh version` 的输出来自 git 标签：正好在 `v1.3` 时是 `1.3`，tag 之后有提交是 `1.3+5`，
工作区有未提交改动则是 `1.3+5-dirty`。发布就是 `git tag -a vX.Y.Z` + `git push --tags`。

## 许可

GPL-3.0。部分组件派生自 [Nyxuri](https://github.com/ech678/Nyxuri)（同为 GPL-3.0），
署名见 [CREDITS.md](CREDITS.md)。
