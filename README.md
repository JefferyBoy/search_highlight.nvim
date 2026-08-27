[English](README.md) | [简体中文](README-zh-rCN.md)

# search_highlight.nvim

Multi-keyword search highlighting plugin. When searching with `/a\|b\|c`, each keyword is automatically highlighted with a different color block, making log analysis and pattern comparison easy.

## Demo

Searching `/error\|warn\|fail` highlights `error`, `warn`, and `fail` in red, green, and blue blocks respectively, instantly distinguishable at a glance.

## Installation

**lazy.nvim**:

```lua
{
  "JefferyBoy/search_highlight.nvim",
}
```

## Usage

No extra setup needed, works right after installation:

1. Run `/` search with multiple keywords separated by `\|`. For example:
   ```
   /error\|warn\|fail\|timeout
   ```
   Each keyword automatically gets a different color highlight.

2. `:nohlsearch` (or mapped `<Esc>`) turns off highlighting, and the plugin clears automatically.

3. Highlighting syncs automatically when switching windows or splits.

### Magic mode

- **very magic** (`\v`): `|` is used directly as the separator, no escaping needed.
  ```
  /\verror|warn|fail
  ```

- **nomagic** (`\V`) or **magic** (`\M`): `\|` is used as the separator (default behavior).
  ```
  /error\|warn\|fail
  ```

### Single keyword

When searching a single keyword, colored highlighting is not enabled, preserving Neovim's native `hlsearch` behavior.

## Configuration

`setup()` accepts an optional `colors` parameter to override the default palette (7-color cycle):

```lua
require('search_highlight').setup({
  colors = {
    { fg = "#1a1c2a", bg = "#ea7183" }, -- red
    { fg = "#1a1c2a", bg = "#96d382" }, -- green
    { fg = "#1a1c2a", bg = "#739df2" }, -- blue
    { fg = "#1a1c2a", bg = "#eaca89" }, -- yellow
    { fg = "#1a1c2a", bg = "#b889f4" }, -- purple
    { fg = "#1a1c2a", bg = "#78cec1" }, -- cyan
    { fg = "#1a1c2a", bg = "#f39967" }, -- orange
  },
})
```

The default palette follows the catppuccin mocha style, suitable for dark themes. You can also pass only part of the colors — the plugin cycles through them automatically.

## How it works

- Listens to the `CmdlineLeave` event, reads the `@/` register after a search command, and splits it into keywords by the separator.
- Calls `matchadd()` for each keyword to create an independent highlight with a higher priority than the native `hlsearch` (priority 0).
- Earlier keywords get higher priority, ensuring that when keywords overlap, the first-entered keyword stays visible.
- Listens to `WinEnter` / `CursorHold` to handle split switching and operations like `*`.
- `WinClosed` automatically cleans up window resources.
