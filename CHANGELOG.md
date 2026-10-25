# Changelog

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
