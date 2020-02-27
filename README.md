# diagnosis-nvim

Nvim built in language server is amazing, but the diagnosis setting that it shipped with default
may not be as great as other LSP plugins. Fortunately, it's very customizable with changing
the default callback function with lua. This plugin tries to focus on wrapping the
diagnosis setting up to make it a more user friendly without adding too much to it.

## Features

- Options to disable/enable virtual text.
- Jump to next/prev diagnostic under your cursor.
- Automatically open pop up window that shows line diagnostic while jumping.
- Show error sign in columns.


## Demo

## Prerequisite
- Neovim nightly
- You should be setting up language server with the help of [nvim-lsp](https://github.com/neovim/nvim-lsp)

## Install

- Install with any plugin manager by using the path on GitHub.
```
Plug 'haorenW1025/floatLf-nvim'
```

## Command

## Options

## Future Work

- [ ] Option to change virtual text format.
- [ ] Option to change diagnosis callback to only toggle when leaving insert mode.
- [ ] Support different signs for different diagnosis level.


