lua require'diagnostic'.modifyCallback()
if g:diagnostic_show_sign == 1
    hi DiagnosticError cterm=bold ctermfg=168 gui=bold guifg=#e06c75
    sign define DiagnosticErrorSign text=✗ texthl=DiagnosticError
endif
