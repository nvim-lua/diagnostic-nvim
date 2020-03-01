if exists('g:loaded_diagnostic') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! PrevDiagnostic lua require'jumpLoc'.jumpPrevLocation() 
command! NextDiagnostic lua require'jumpLoc'.jumpNextLocation() 
command! OpenDiagnostic lua require'jumpLoc'.openDiagnostics() 

" lua require'diagnostic'.modifyCallback()

if ! exists('g:diagnostic_enable_virtual_text')
    let g:diagnostic_enable_virtual_text = 0
endif

if ! exists('g:diagnostic_show_sign')
    let g:diagnostic_show_sign = 1
endif

if ! exists('g:diagnostic_insert_delay')
    let g:diagnostic_insert_delay = 1
endif

if ! exists('g:diagnostic_auto_popup_while_jump')
    let g:diagnostic_auto_popup_while_jump = 1
endif




let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_diagnostic = 1
