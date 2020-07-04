# diagnostic-nvim

The built- in Nvim language server support is amazing, but the diagnostics setting
that it shipped with it by default may not be as great as other LSP plugins.
Fortunately, it's very customizable with changing the default callback function
with lua. This plugin tries to focus on wrapping the diagnostics setting up to
make it a more user friendly without adding too much to it.

## Features

- Options to disable/enable virtual text.
- Pipe diagnostic information into location list.
- Jump to next/previous diagnostic under your cursor.
- Automatically open pop up window that shows line diagnostic while jumping.
- Show error sign in columns.
- Show error underline in symbols.
- Delay diagnostic when you're in insert mode.

## Demo
![Demo](https://user-images.githubusercontent.com/35623968/75627012-6824f380-5c07-11ea-8f25-59ce1751e902.gif)

## Prerequisites

- Neovim nightly
- You should set up your language server of choice with the help of [nvim-lsp](https://github.com/neovim/nvim-lsp)

## Install

- Install with any plugin manager by using the path on GitHub.

```vim
Plug 'nvim-lua/diagnostic-nvim'
```

## Setup

- Diagnostic-nvim requires several autocommands set up to work properly. You should
  set it up using the `on_attach` function like this.

```vim
lua require'nvim_lsp'.pyls.setup{on_attach=require'diagnostic'.on_attach}
```

- Change `pyls` to whichever language server you're using.

## Commands

- Use `PrevDiagnostic` and `NextDiagnostic` to jump to the previous and next diagnostic
  under your cursor.
- `PrevDiagnosticCycle` and `NextDiagnosticCycle` not only jump to the previous and next diagnostic but also
cycle through the diagnostic if you're at the first or last diagnostic.
- `OpenDiagnostic` will open a location list and jump back to previous window.

## Options

### Enable/Disable virtual text

- Diagnostic-nvim has an option that lets you toggle the virtual text. Virtual text
  is disabled by default. You can enable it by

```vim
let g:diagnostic_enable_virtual_text = 1
```

### Change virtual text prefix

- Diagnostic-nvim provides an option to change the virtual text prefix, the
  default prefix is '■', but if you have nerd font or other power line font
  support, you can make it a little more fancy by adding something like:

```vim
let g:diagnostic_virtual_text_prefix = ' '
```

### Trimming virtual text

- Sometimes you can be working with language which has long virtual text,
  Diagnostic-nvim provides an option to trim the virtual text to fit your usage by

```vim
let g:diagnostic_trimmed_virtual_text = '20'
```

- If the virtual text exceeds the value that you set, `...` will be displayed in the end.
- Note that setting this option to `0` means that it will only show the prefix.
- By default, this value is set to `v:null`, which means it's not trimmed at all.

### Spaces before virtual text
- By default, there will be only a space before virtual text. You can add more spaces by

```vim
let g:space_before_virtual_text = 5
```

### Enable/Disable Sign

- By default, the build-in Nvim LSP will show a sign on every line that you have
  a diagnostic message on. You can turn this off by

```vim
let g:diagnostic_show_sign = 0
```

- The default priority of the diagnostic sign is 20. You can customize it by

```vim
let g:diagnostic_sign_priority = 20
```

- Make sure to use the latest branch of Neovim which has sign support.

- If you want to change the symbols of sign, use `sign_define` to change it

```vim
call sign_define("LspDiagnosticsErrorSign", {"text" : "E", "texthl" : "LspDiagnosticsError"})
call sign_define("LspDiagnosticsWarningSign", {"text" : "W", "texthl" : "LspDiagnosticsWarning"})
call sign_define("LspDiagnosticsInformationSign", {"text" : "I", "texthl" : "LspDiagnosticsInformation"})
call sign_define("LspDiagnosticsHintSign", {"text" : "H", "texthl" : "LspDiagnosticsHint"})
```

### Enable/Disable Underline

- By default, the build-in Nvim LSP will show a underline on every symbol that
  you have a diagnostic message on. You can turn this off by

```vim
let g:diagnostic_enable_underline = 0
```

### Enable/Disable auto popup window

- When you jump to next or previous diagnostic, line diagnostic message will popup
  in a popup window, you can disable it by

```vim
let g:diagnostic_auto_popup_while_jump = 0
```

### Enable/Disable insert delay

- Neovim's built-in LSP support will keep sending diagnostic messages when you're
  in insert mode. Sometimes this can be kind of distraction especially when you have
  virtual text enabled. If you don't want to show diagnostics while in insert mode,
  set the following

```vim
let g:diagnostic_insert_delay = 1
```

## WARNING

- This plugin is in the early stages and might have unexpected issues.
- Feel free to post issues on any unexpected behavior or open a feature request!
