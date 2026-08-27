[English](README.md) | [简体中文](README-zh-rCN.md)

# search_highlight.nvim

多关键词搜索高亮插件。使用 `/a\|b\|c` 搜索时，每个关键词自动分配不同颜色的色块高亮，方便日志分析和模式对比。

## 效果

搜索 `/error\|warn\|fail` 时，`error`、`warn`、`fail` 分别以红、绿、蓝色块高亮，一目了然。

## 安装

**lazy.nvim**:

```lua
{
  "JefferyBoy/search_highlight.nvim",
}
```

## 使用

无需额外操作，安装即用：

1. 执行 `/` 搜索，用 `\|` 分隔多个关键词。例如：
   ```
   /error\|warn\|fail\|timeout
   ```
   每个关键词自动获得不同颜色高亮。

2. `:nohlsearch`（或映射的 `<Esc>`）关闭高亮，插件自动清除。

3. 切换窗口、分屏时高亮自动同步。

### 魔法模式

- **very magic** (`\v`): `|` 直接作为分隔符，无需转义。
  ```
  /\verror|warn|fail
  ```

- **nomagic** (`\V`) 或 **magic** (`\M`): `\|` 作为分隔符（默认行为）。
  ```
  /error\|warn\|fail
  ```

### 单个关键词

搜索单个关键词时不启用彩色高亮，保持 Neovim 原生 `hlsearch` 行为。

## 配置

`setup()` 接受可选的 `colors` 参数，覆盖默认色板（7 色循环）：

```lua
require('search_highlight').setup({
  colors = {
    { fg = "#1a1c2a", bg = "#ea7183" }, -- 红
    { fg = "#1a1c2a", bg = "#96d382" }, -- 绿
    { fg = "#1a1c2a", bg = "#739df2" }, -- 蓝
    { fg = "#1a1c2a", bg = "#eaca89" }, -- 黄
    { fg = "#1a1c2a", bg = "#b889f4" }, -- 紫
    { fg = "#1a1c2a", bg = "#78cec1" }, -- 青
    { fg = "#1a1c2a", bg = "#f39967" }, -- 橙
  },
})
```

默认色板为 catppuccin mocha 风格，适合深色主题。只传部分颜色也可以，插件会自动循环使用。

## 原理

- 监听 `CmdlineLeave` 事件，搜索命令执行后读取 `@/` 寄存器，按分隔符拆分成关键词。
- 对每个关键词调用 `matchadd()` 创建独立高亮，优先级高于原生 `hlsearch`（优先级 0）。
- 靠前的关键词优先级更高，确保叠词时先输入的关键词可见。
- 监听 `WinEnter` / `CursorHold` 处理分屏切换和 `*` 等操作。
- `WinClosed` 自动清理窗口资源。
