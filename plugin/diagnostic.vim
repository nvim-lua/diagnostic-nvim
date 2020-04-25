if exists('g:loaded_diagnostic') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! PrevDiagnostic lua require'jumpLoc'.jumpPrevLocation()
command! PrevDiagnosticCycle lua require'jumpLoc'.jumpPrevLocationCycle()
command! NextDiagnostic lua require'jumpLoc'.jumpNextLocation()
command! NextDiagnosticCycle lua require'jumpLoc'.jumpNextLocationCycle()
command! OpenDiagnostic lua require'jumpLoc'.openDiagnostics()

" lua require'diagnostic'.modifyCallback()

if ! exists('g:diagnostic_enable_virtual_text')
    let g:diagnostic_enable_virtual_text = 0
endif

if ! exists('g:diagnostic_virtual_text_prefix')
    let g:diagnostic_virtual_text_prefix = '■'
endif

if ! exists('g:diagnostic_trimmed_virtual_text') || g:diagnostic_trimmed_virtual_text < 0
    let g:diagnostic_trimmed_virtual_text = v:null
endif

if ! exists('g:space_before_virtual_text') || g:space_before_virtual_text <= 0
    let g:space_before_virtual_text = 1
endif

if ! exists('g:diagnostic_show_sign')
    let g:diagnostic_show_sign = 1
endif

if ! exists('g:diagnostic_insert_delay')
    let g:diagnostic_insert_delay = 0
endif

if ! exists('g:diagnostic_auto_popup_while_jump')
    let g:diagnostic_auto_popup_while_jump = 1
endif

if ! exists('g:diagnostic_level')
    let g:diagnostic_level = 'Warning'
endif


let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_diagnostic = 1
