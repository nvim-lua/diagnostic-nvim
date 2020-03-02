# diagnostic-nvim

Nvim built in language server is amazing, but the diagnosis setting that it shipped with default
may not be as great as other LSP plugins. Fortunately, it's very customizable with changing
the default callback function with lua. This plugin tries to focus on wrapping the
diagnosis setting up to make it a more user friendly without adding too much to it.

## Features

- Options to disable/enable virtual text.
- Pipe diagnostic information into location list.
- Jump to next/previous diagnostic under your cursor.
- Automatically open pop up window that shows line diagnostic while jumping.
- Show error sign in columns.
- Delay diagnostic when you're in insert mode.

## Demo
![Demo](https://user-images.githubusercontent.com/35623968/75627012-6824f380-5c07-11ea-8f25-59ce1751e902.gif)

## Prerequisite
- Neovim nightly
- You should be setting up language server with the help of [nvim-lsp](https://github.com/neovim/nvim-lsp)

## Install

- Install with any plugin manager by using the path on GitHub.
```
Plug 'haorenW1025/diagnostic-nvim'
```

## Setup
- Diagnostic-nvim require several autocommand set up to work properly, you should
  set it up using the `on_attach` function like this.
  ```
  lua require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
  ```
- Change `pyls` to whatever language server you are using.

## Command
- Use `PrevDiagnostic` and `NextDiagnostic` to jump to previous and next diagnostic
  under your cursor.
- `OpenDiagnostic` will open location list and jump back to previous window.

## Options

### Enable/Disable virtual text
- Diagnostic-nvim have an option that let you toggle up virtual text. Virtual text
is disable by default, you can open enable it by
```
let g:diagnostic_enable_virtual_text = 1
```

### Change virtual text prefix
- Diagnostic-nvim provide an option to change the virtual text prefix, the default
prefix is '■', but if you have nerd font or other power line font support, you can
make it a little more fancy by
```
let g:diagnostic_virtual_text_prefix = ' '
```

### Trimming virtual text
- Sometimes you can be working with language which have long virtual text, Diagnostic-nvim
provide a an option to trimmed the virtual text to fit your usage by
```
let g:diagnostic_trimmed_virtual_text = '20'
```
- If virtual text exceed the value that you set, `...` will be displayed in the end.
- Note that setting this option to `0` means that only shows prefix.
- By default, this value is set to `v:null`, which means no trimmed at all.

### Enable/Disable Sign
- By default, built-in LSP will show sign on every line that you have diagnostic
message on it. You can turn it off by
```
let g:diagnostic_show_sign = 0
```
- Make sure to use the latest branch of neovim which have sign support.

### Enable/Disable auto popup window
- When you jump to next or previous diagnostic, line diagnostic message will popup
in a popup window, you can disable it by
```
let g:diagnostic_auto_popup_while_jump = 0
```

### Enable/Disable insert delay
- Neovim built in language server will keep sending diagnostic message when you're
in insert mode, sometimes it could be kind of distraction especially when you have
virtual text enable. If you don't want to show diagnostic while insert mode, turn
on this option by
```
let g:diagnostic_insert_delay = 1
```

<!-- ## Future Work -->

<!-- - [ ] Option to change virtual text format. -->

## WARNING
This plugin is in early stage, might have unexpected issues.
