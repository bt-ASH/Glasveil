# Changelog

## [Unreleased]

### Fixed
- **壁纸检测取错显示器名**：`niri msg focused-output` 的型号里也带括号
  （`Output "PNP(RZD) TYPE-C Unknown" (DP-1)`），原 `awk -F '[()]' '{print $2}'`
  会取到 `RZD`，导致 `matugen-update` / `theme-toggle` 匹配不到 awww 输出、
  回退到 waypaper 里的旧壁纸。改为 `niri msg -j focused-output | jq -r .name`，
  并保留 sed 兜底。
- **matugen 在 fish 下生成中断 / rofi 模板缺失**：
  matugen 用当前 `$SHELL`（本机 fish）执行 `post_hook`，原来带 `if`、
  `& || true` 的写法会被 fish 语法拒绝；改为统一用 `bash -c` 包一层，
  并给 waybar / pywalfox / btop / tmux / swayosd 的 hook 加上存在性判断与兜底，
  工具没装、进程没跑时不再报错。
  `~/.config/matugen/templates/rofi-colors.rasi` 之前没部署导致
  “rofi template doesn't exist, skipping”；已补上软链（`install.sh deploy`
  本来就会部署该文件）。现在 `matugen-update` 全流程零报错、退出码 0。

### Added
- **视频壁纸（mpvpaper）**：新增 `configs/scripts/wallpaper-apply.sh` 统一判断类型——
  `file --mime-type` 为 `video/*` 或视频扩展名（mp4/webm/mkv/mov/m4v/avi/flv/wmv）
  时用 `mpvpaper -o "no-audio loop-file=inf panscan=1.0" "*" <文件>`
  （`loop-file=inf` 无限循环，`panscan=1.0` 等比铺满并裁切，效果与 awww 的填充一致），
  图片仍走 `awww img`；
  两者互斥：视频先 `awww kill` 再启动 mpvpaper，切回图片时先结束 mpvpaper
  再拉起 awww-daemon。`wallsel.sh`、`wallpicker.sh`、
  `restore-wallpaper.sh` 都改走这个 helper，选择器也会列出视频并用 ffmpeg 首帧做缩略图；
  `matugen-update.sh` 无参时优先从 mpvpaper 进程取当前视频（awww 已 kill 也能取到），
  用 ffmpeg 把首帧缩到 500px 再取色（hyprlock 链接按视频处理移除）；
  `theme-toggle.sh` 同样优先识别 mpvpaper 视频，并通过新增的
  `wallpaper-frame.sh` 取首帧后再跑 matugen；
  **动图 webp** 也按首帧取色（`wallpaper-frame.sh` 与 `matugen-update.sh` 都
  显式取 `[0]` 首帧），但 webp 壁纸仍然由 awww 显示/播放，不走 mpvpaper；
  **hyprlock**：webp / 视频取首帧（1920 宽 PNG，缓存在
  `~/.cache/matugen-strategy/hypr_frames/`）链接为锁屏背景，交给 hyprlock
  自己做毛玻璃；普通图片仍然直接链接原图；
  `rules.kdl` 增加 mpvpaper 的 `place-within-backdrop` 图层规则；
  `install.sh` 的 AUR 依赖加入 `mpvpaper`。
- **命令部署到 `~/.local/bin`**：`install.sh` 新增 `local_bin_targets` 映射，
  `configs/scripts/matugen-update.sh` 除正常部署到 `~/.config/scripts/` 外，
  还会额外软链为 `${XDG_BIN_HOME:-~/.local/bin}/matugen-update`；
  deploy / backup / restore 都覆盖（备份里用 `local-bin/` 区分目标位置）。
  仓库根 `bin/` 目录取消，旧的 166 行副本淘汰，统一到新版
  （niri + awww 探测、`-f`、重复跳过）；`~/.local/bin/matugen-update`
  已改为直接指向 `configs/scripts/matugen-update.sh` 并验证可正常跑完。
- **rofi 启动器与剪贴板菜单（niri / Wayland）**：`configs/rofi/` 新增
  `config.rasi`（drun，fuzzy + fzf 排序、Papirus 图标、圆角半透明窗口）、
  `clipboard.rasi` 与 `clipboard.sh`（读 clipse 的 `clipboard_history.json`
  → rofi 选择 → `wl-copy`，文本保留换行、图片按原 MIME 写回）。
  配色不写死：新增 matugen 模板 `configs/matugen/templates/rofi-colors.rasi`
  → `~/.config/rofi/colors.rasi`（`[templates.rofi]`），全部 8 位 hex，
  避开 rofi 的 rgba 变量在 `element` 背景上回退白色的问题。
  绑定写在 `configs/niri/__custom__.kdl`（具体键位见 README，本文件不记录，
  免得和配置漂移）；原 Steam 壁纸速览绑定移除（命令 `wallpapers` 仍在，
  浏览器画廊保留）。`install.sh` 仓库依赖加入 `rofi`。
  同时恢复 `wallpaper.rasi` 壁纸选择器主题与 `.module.toml` 清单。
- **壁纸选择器 wallsel（rofi 卡片预览）**：新增 `configs/rofi/wallsel.sh` +
  `wallsel.rasi`，由 hyprdots 的 `wallsel-v2.sh` 改写：屏宽改用 niri IPC
  （`focused-output`）、竖版圆角卡片 + 文件名标签、当前壁纸自动预选中、
  `awww` 应用后与 waypaper 走同一套善后（见下）；大体积动图 webp 先用 ffmpeg 抠首帧，
  避免 ImageMagick 解全部帧卡死。选择卡片时方向键与 vim 键位都可用
  （`-kb-row-*`，字母键因此不再参与文件名过滤）；`install.sh` 依赖加入 `imagemagick`。
- **壁纸应用后的善后统一走 waypaper 的配置**：新增
  `configs/scripts/wallpaper-post.sh`，先把握手壁纸写回
  `~/.config/waypaper/config.ini` 的 `wallpaper =`（开机 `restore-wallpaper.sh`
  与无参 `matugen-update` 都读它），再原样执行同一文件里的 `post_command`
  （当前为 `/home/ash/.local/bin/matugen-update && (tmux source-file ~/.tmux.conf …)`）。
  `wallsel.sh` 与 `wallpicker.sh` 都改为调用它，不再各自硬编码 matugen-update。

### Removed
- **Spotify / Spicetify 主题支持整体移除**：删除
  `configs/matugen/templates/spotify-color.ini`、`scripts/inject-spicetify-color.sh`、
  `scripts/apply-spicetify-colors.sh`、`spotify-color.fallback.ini`，
  以及 `config.toml` 里的 `[templates.spicetify]` 模板配置（换壁纸不再渲染 Spotify 配色）；
  `install.sh` 的 `spotify` 子命令、辅助函数、交互菜单第 7 项、`OPTIONAL_PKGS` 里的
  `spicetify-cli` 与相关文档一并删除。本机也已还原客户端
  （`spicetify restore` 取回原版 `xpui.spa` / `login.spa`，并清理
  `~/.config/spicetify`、`~/.local/state/spicetify`）。

### Fixed
- **浅色模式下 TUI 代码块看不清**：Miyu 等 TUI 的语法高亮用的是 xterm **256 色立方体**
  （实测 `#d7d7ff`=189、`#afd7af`=151），这些索引不受 matugen 的 16 色主题控制，
  在浅底上对比度只有 1.3~1.5。
  新增 `configs/scripts/kitty-cube-tune.sh`：浅色模式下把 color16–255 中较亮的颜色
  压暗 20%（`factor=0.8`，可调），由 `theme-toggle.sh` 在切明暗时自动 on/off。
  之后改为 **按模式独立系数**：`gen <factor> [--light|--dark]`，
  light = 0.65、dark = 1.0（不处理，不生成文件），
  系数为 1.0 时该模式不启用覆盖（`kitty-cube-tune.sh show` 可查）。

### Removed
- **`configs/waypaper/` 移出仓库**：waypaper 的 `config.ini` / `style.css`
  改由本机 `~/.config/waypaper/` 自维护（现有真实文件保留，`deploy` 不再覆盖）；
  `waypaper` 命令与 `post_command`（matugen 刷新）保持不变。
- **视频壁纸 / mpvpaper 支持**：壁纸切换统一走 `awww`。
  `wallpaper_picker` 后端重写为纯 awww（含 matugen 刷新），去掉视频扫描、ffmpeg 缩略图、
  “Live/Static” 分类与徽标；`rules.kdl` 移除 mpvpaper 图层规则；`install.sh` 的 AUR 依赖去掉 mpvpaper；
  `get_current_wallpaper()` 改为查 `awww query`。
- `waypaper` 配置：`backend` 从 `mpvpaper` 改为 **`awww`**，删除 `mpvpaper_*` 与过时的 `swww_*` 键；
  新增 `configs/waypaper/`（config.ini + style.css）入仓。

### Changed
- **rofi 壁纸选择器的缩略图改成 waypaper 同款网格**：
  新增 `configs/rofi/wallpaper.rasi`：窗口与卡片都不画底色（`background-color:
  transparent`），缩略图直接浮在壁纸上，选中项只有 `#7aa2f7` 蓝色圆角描边；
  底部一条圆角搜索栏，**宽度与缩略图网格等宽**（`margin: 0px 6px`）、
  圆角 18px 与卡片风格统一、占位文字「搜索壁纸」，
  取代参考图里那排显示器/暗度/偏移按钮；
  单元格改为 4 列 × 2 行、`element-icon size: 210px` → 单元格约 398×224
  （≈16:9），16:9 壁纸实测占卡片 97%×95%，竖图/超宽图按原比例居中不裁切；
  注意 rofi 的 `*{}` rgba 变量用在 `element` 背景上会回退成白色，透明值必须写字面量；
  `wallpicker.sh` / `wallpapers` 两个 rofi 选择器共用该主题，
  `wallpicker.sh` 同时改为 awww 应用 + matugen 刷新、缩略图并行生成。

- **锁屏改成 Noctalia 风格**（hyprlock 实现，不依赖 Noctalia 常驻）：
  模糊壁纸背景、居中大时钟 + 日期、圆角卡片式密码框；
  新增 matugen 模板 `hyprlock-colors.conf`（surface_variant 88% 卡片色、outline 描边、带 alpha），
  配色跟随壁纸与明暗。

- `install.sh` 的 shell 补全脚本从顶层 `completions/` 移到 `configs/fish/completions/`，
  与 fish 配置同目录（`./install.sh completion fish|bash|zsh` 仍然可用）。

## [1.3] - 2026-10-26

### Added
- **Spotify / Spicetify 主题**：`./install.sh spotify [配色方案]`，配色由 `templates/spotify-color.ini`
  经 matugen 渲染，`inject-spicetify-color.sh` 注入 Spicetify（含 fallback 配色）
- **Zed 主题**：单文件同时产出 `Glasveil Dark` / `Glasveil Light`（用 matugen adaptive 变体）
- `install.sh version` 子命令

### Changed
- 版本号改为 **git tag 单源推导**：`v1.3` / `v1.3+5` / `v1.3+5-dirty`，
  `--help` 与交互菜单抬头不再硬编码版本
- 补全脚本覆盖新增的 `spotify` / `version` 子命令

## [0.1.0] - 2026-10-25

首个公开快照。

### Added
- niri 配置（结构对齐 Nyxuri）：`config.kdl` 统一 include，输入/显示器/规则/动画/特效拆分
- Orbit 星环启动器（工具链在 `configs/niri/tools/`）
- Sweep 缓存清理 TUI（`configs/niri/scripts/clean-cache.py`）
- 明暗配色切换、护眼模式
- 电池保护启动项 `battery-care.sh`
- matugen 取色管线：niri/kitty/GTK/fcitx5(NyxMellow)/eww/fastfetch/wifitui/palette.toml
- eww 胶囊状态栏（透明底、胶囊模块、工作区选中态）
- wifitui 配色模板
