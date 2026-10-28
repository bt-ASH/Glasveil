# Changelog

## [Unreleased]

### Fixed
- **浅色模式下 TUI 代码块看不清**：Miyu 等 TUI 的语法高亮用的是 xterm **256 色立方体**
  （实测 `#d7d7ff`=189、`#afd7af`=151），这些索引不受 matugen 的 16 色主题控制，
  在浅底上对比度只有 1.3~1.5。
  新增 `configs/scripts/kitty-cube-tune.sh`：浅色模式下把 color16–255 中较亮的颜色
  压暗 20%（`factor=0.8`，可调），由 `theme-toggle.sh` 在切明暗时自动 on/off。
  之后改为 **按模式独立系数**：`gen <factor> [--light|--dark]`，
  light 默认 0.65、dark 默认 0.9，各自生成 `themes/xterm-cube-{light,dark}.conf`，
  系数为 1.0 时该模式不启用覆盖（`kitty-cube-tune.sh show` 可查）。

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
- `Mod+Shift+A` Orbit 星环启动器（工具链在 `configs/niri/tools/`）
- Sweep 缓存清理 TUI（`configs/niri/scripts/clean-cache.py`）
- `Mod+Shift+N` 明暗配色切换、`Mod+N` 护眼模式
- 电池保护启动项 `battery-care.sh`
- matugen 取色管线：niri/kitty/GTK/fcitx5(NyxMellow)/eww/fastfetch/wifitui/palette.toml
- eww 胶囊状态栏（透明底、胶囊模块、工作区选中态）
- wifitui 配色模板
