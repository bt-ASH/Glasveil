<div align="center">

# Glasveil

**/ˈɡlæsveɪl/** (glass veil) · A Material You–style [niri](https://github.com/YaLteR/niri) desktop configuration
<br /><sub>Glassy windows · wallpaper-based color extraction · floating orbit launcher · eww capsule status bar</sub>

</div>

## What is this

A complete snapshot of a personal niri setup: compositor keybindings and rules, the eww status bar, kitty/fish,
matugen color templates and scripts, plus a few small self-written tools (orbit launcher entry, cache cleanup,
light/dark toggle, eye comfort, battery protection, floating/tiled focus switching).

## Key features

- **One-stop wallpaper-based color extraction**: `matugen` extracts colors using the same `m3-content` scheme as Noctalia, generating
  niri / kitty / GTK3·4 / fcitx5 themes / eww / **rofi** / fastfetch / wifitui / zed / yazi / starship / btop / cava / hyprlock…
- **`Mod+Shift+N` light/dark toggle**: re-runs matugen + switches `gsettings` + hot-reloads niri/kitty/fcitx5/eww
- **Video wallpapers**: `wallpaper-apply.sh` routes by MIME type — videos go to `mpvpaper` (infinite loop + aspect-fill), images still go through `awww`;
  the two are mutually exclusive, and color extraction uniformly grabs the first frame via ffmpeg
- **Glass feel**: windows at 0.9 opacity + `blur passes 3`; `effects.kdl` is a symlink to switch between normal/eye-comfort
- **`Mod+N` eye comfort**: disables blur (including the eww / rofi layer surfaces), increases opacity, `wlsunset` 5500K
- **`Mod+Shift+A` Orbit ring**: GTK3 + gtk-layer-shell fullscreen overlay, cairo vector drawing
- **rofi takes over the shell**: `Mod+R` launcher (drun) / `Mod+V` clipboard history (clipse → rofi → `wl-copy`) /
  `Mod+W` wallpaper picker / `Mod+Shift+G` wallpaper gallery, with colors rendered by matugen
- **`Mod+W` wallpaper picker**: nine fullscreen vertical cards, zero widgets; selected item only gets a 2px mint outline;
  the background image along with the shadows of the nine strips is pre-baked into a JPEG by `tools/make-picker-bg.py`, aligned 1:1 with the rofi window
- **Pointer keybinding layer**: `ydotool` binds `Alt+H/J/K/L` (movement), `Alt+S`/`Alt+X` (left/right click),
  `Alt+,`/`Alt+.` (scroll) to the keyboard
- **Sweep cache cleanup**: checkbox-style TUI, supports dry-run and whitelist fencing
- **eww capsule status bar**: transparent background, capsule modules, primary-tinted active workspace state
- **Battery protection**: locks the charge threshold at 80% on boot (requires one-time root configuration)

### rofi pitfalls in the wallpaper picker theme

The header comments of `configs/rofi/wallpaper.rasi` contain the full derivation; three are the easiest to trip over:

- `element-icon`'s `size` is the side length of the **box**; for portrait images you must pair it with `squared: false`, otherwise they get squeezed into a square;
- with `layout: horizontal` the two axes swap: `columns: 1` is actually the row count, and `lines: 9` is the number of items per row;
- rgba **variables** on the `element` background fall back to white; always use literals for transparency/tinting.

## Directory structure

```
Glasveil/
├── configs/
│   ├── niri/        # kdl + scripts/ + tools/ + __presets__/
│   ├── kitty/  fish/  eww/  fastfetch/  matugen/  rofi/
│   ├── yazi/  wireplumber/  xdg-desktop-portal/  scripts/
│   └── starship.toml
├── tools/           # one-off generation scripts (make-picker-bg, mockup renders)
├── install.sh
├── LICENSE (GPL-3.0) · CREDITS.md
└── README.md / README.zh-CN.md
```

## Installation

```bash
git clone <this repo> ~/Glasveil && cd ~/Glasveil
./install.sh                 # interactive menu (deploy / deps / both / backup / restore / list backups)
./install.sh deploy          # deploy configs only (default; --copy to copy, --dry-run to preview)
./install.sh deps            # install dependencies only (repo packages + AUR; --repo-only to skip AUR)
./install.sh all             # deps + configs
./install.sh backup before-tweaking    # snapshot / list-backups to list / restore latest to roll back
```

## Shell completion

`./install.sh completion fish|bash|zsh` outputs a completion script; for fish, drop it into `~/.config/fish/completions/`,
and `restore <TAB>` will automatically list existing backup tags.

Dependencies (Arch): `niri matugen kitty fish eww rofi imagemagick fcitx5-gtk wifitui starship yazi`
+ AUR/optional: `awww`, `mpvpaper` (video wallpapers), `clipse` (clipboard history source),
`gtk-layer-shell python-gobject python-cairo` (Orbit ring).

Color pipeline: wallpaper → `wallpaper-apply.sh` (video → `mpvpaper`, image → `awww`) →
`wallpaper-post.sh` (writes back to waypaper's `config.ini` and runs `post_command`) → `matugen-update` → all theme files.

`configs/scripts/matugen-update.sh` is additionally symlinked as `~/.local/bin/matugen-update` during `deploy`
(waypaper's `post_command` uses this path); the `bin/` at the repo root has been removed.

## Versioning

The output of `./install.sh version` comes from git tags: exactly at `v1.3` it's `1.3`, with commits after the tag it's `1.3+5`,
and with uncommitted changes in the working tree it's `1.3+5-dirty`. Releasing is `git tag -a vX.Y.Z` + `git push --tags`.

## License

GPL-3.0. Some components are derived from [Nyxuri](https://github.com/ech678/Nyxuri) (also GPL-3.0);
see [CREDITS.md](CREDITS.md) for attribution.
