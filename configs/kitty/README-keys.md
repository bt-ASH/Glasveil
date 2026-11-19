# kitty 配置快捷键

> 只讲 `configs/kitty/kitty.conf` 里**实际定义**的 `map` / `mouse_map`。
> kitty 自带的 `Ctrl+Shift+*` 不在这里，需要时按 `Ctrl+Shift+F1` 看它的内置帮助。
> 路径：仓库 `configs/kitty/README-keys.md` ←→ 部署后 `~/.config/kitty/README-keys.md`

## 最常用

| 快捷键 | 作用 | 实现 |
|---|---|---|
| `Ctrl+C` | 有选中 → 复制到剪贴板并清掉选中；没选中 → 正常发 SIGINT（中断程序） | `map ctrl+c copy_and_clear_or_interrupt` |
| `Ctrl+V` | 从剪贴板粘贴 | `map ctrl+v paste_from_clipboard` |
| `鼠标右键` | 粘贴（按下即触发，不需要拖选） | `mouse_map right press ungrabbed paste_from_clipboard` |

## 编辑

| 快捷键 | 作用 | 发送的字节 |
|---|---|---|
| `Ctrl+Backspace` | 删掉光标前一个词 | `\x17`（`^W` / `werase`） |
| `Ctrl+Delete` | 删掉光标后一个词 | `\x1bd`（`M-d`） |

> 这两条走 `send_text all`，所以行为由 shell / 编辑器决定：fish 里删一个词、vim 插入模式里删一个词。

## 分屏方向

| 快捷键 | 作用 | 实现 |
|---|---|---|
| `Ctrl+Shift+J` | **上下**分（两个窗口一上一下） | `map ctrl+shift+j launch --cwd=current --location=hsplit` |
| `Ctrl+Shift+H` | **左右**分（两个窗口并排） | `map ctrl+shift+h launch --cwd=current --location=vsplit` |
| `Ctrl+Shift+Enter` | 按当前布局自动分（kitty 内置，没动它） | `new_window` |

命名容易搞反，记法：**hsplit = 横着切一刀 → 上下**，**vsplit = 竖着切一刀 → 左右**。
`--cwd=current` 让新分屏继承当前目录，不然会跳到 `$HOME`。

> `Ctrl+Shift+D` 现在**空着**了（上一版是它做上下分），想两个键都留就再补一行 `map ctrl+shift+d ...`。

## 标签页

| 快捷键 | 作用 | 实现 |
|---|---|---|
| `Ctrl+Shift+N` | 在**当前 kitty 窗口**开一个新页（tab） | `map ctrl+shift+n launch --cwd=current --type=tab` |
| `Ctrl+Shift+T` | 新页（kitty 内置，行为一样，没动它） | `new_tab` |

### `Ctrl+Shift+N` 的原用途

kitty 默认把 `Ctrl+Shift+N` 绑成 **`new_os_window`** —— 开一个**全新的 OS 窗口**（不是新页）。
改成新页后这条默认行为就没了。要保留，配置里有一行注释好的备份，去掉注释即可：

```
map ctrl+shift+m new_os_window
```

`Ctrl+Shift+M` 已核对是空闲键位。

### `Ctrl+Shift+H` 原来是干嘛的

它原本是 kitty 内置的 **`show_scrollback`**：用 `less` 打开回滚缓冲，能翻历史、能搜、保留颜色。
man page 原文 `ctrl+shift+h → Browse scrollback in less`。

改成左右分屏后，这条功能挪到了 **`Ctrl+Shift+K`**（原本空闲）：

```
map ctrl+shift+k show_scrollback
```

不想要就删掉那行；想要别的键，换 `ctrl+shift+` 后面那个字母即可（`d`/`h`/`k` 之外的常用键位大多被 kitty 占了）。

## 字号

| 快捷键 | 作用 | 实现 |
|---|---|---|
| `Ctrl+=` | 字号 +1.0 | `map ctrl+equal change_font_size all +1.0` |
| `Ctrl+-` | 字号 −1.0 | `map ctrl+minus change_font_size all -1.0` |
| `Ctrl+0` | 回到配置里的 12.0 | `map ctrl+0 change_font_size all 0` |

> `all` = 作用于所有窗口，不只是当前分屏。

## 剪贴板搬运

| 快捷键 | 作用 | 实现 |
|---|---|---|
| `Ctrl+A` | 把 `@text` 这一目标文本送进系统剪贴板 | 见下 |

```
map ctrl+a pipe @text clipboard sh -c "wl-copy 2>/dev/null || xclip -selection clipboard"
```

两个坑要说清：

1. **不是「全选」**。`@text` 是 kitty `pipe` 的目标之一，**不等于**整个回滚缓冲。
   想要连历史一起送，要把目标换成 `@screen_scrollback`（本机未实测）。
2. **不是「选择到剪贴板」**。文件里另有 `copy_on_select no`，鼠标拖选只进 primary selection，
   不会自动进剪贴板 —— 要进剪贴板用 `Ctrl+C` 或这条 `Ctrl+A`。

## 明确没有绑定的

| 想按 | 现状 |
|---|---|
| `Ctrl+滚轮` 调字号 | **没绑**。`kitty.conf` 里那行只是注释占位，kitty 默认也没这个行为 |

真要的话得自己加（`Ctrl+滚轮` 在 vim / less 等 TUI 里另有含义，会抢掉）：

```
mouse_map ctrl+scroll_up   change_font_size all +1.0
mouse_map ctrl+scroll_down change_font_size all -1.0
```

## 一页速记

```
Ctrl+C   复制 / 中断        Ctrl+V  粘贴（右键同）
Ctrl+Shift+J  上下分   Ctrl+Shift+H  左右分   Ctrl+Shift+N  新页
Ctrl+Backspace  删前一个词   Ctrl+Delete  删后一个词
Ctrl+=  大   Ctrl+-  小   Ctrl+0  还原
Ctrl+A   把当前文本塞进剪贴板
Ctrl+Shift+K  用 less 翻回滚
```
