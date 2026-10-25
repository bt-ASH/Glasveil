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
  niri / kitty / GTK3·4 / fcitx5 皮肤 / eww / fastfetch / wifitui / yazi / starship / btop / cava…
- **`Mod+Shift+N` 明暗切换**：重跑 matugen + 切 `gsettings` + 热重载 niri/kitty/fcitx5/eww
- **玻璃质感**：窗口 0.9 不透明度 + `blur passes 3`；`effects.kdl` 软链切换普通/护眼
- **`Mod+N` 护眼**：关模糊、透明度加重、`wlsunset` 5500K
- **`Mod+Shift+A` Orbit 星环**：GTK3 + gtk-layer-shell 全屏覆盖层，cairo 矢量绘制
- **Sweep 缓存清理**：勾选式 TUI，支持干跑、白名单围栏
- **eww 胶囊状态栏**：透明底、胶囊模块、工作区选中态 primary 淡染
- **电池保护**：开机锁 80% 充电阈值（需一次性 root 配置）

## 目录结构

```
Glasveil/
├── configs/
│   ├── niri/        # kdl + scripts/ + tools/ + __presets__/
│   ├── kitty/  fish/  eww/  fastfetch/  matugen/
│   ├── yazi/  wireplumber/  xdg-desktop-portal/  scripts/
│   └── starship.toml
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

## 许可

GPL-3.0。部分组件派生自 [Nyxuri](https://github.com/ech678/Nyxuri)（同为 GPL-3.0），
署名见 [CREDITS.md](CREDITS.md)。
