if exists('g:loaded_diagnosis') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

command! PrevDiagnostic lua require'jumpLoc'.jumpPrevLocation() 
command! NextDiagnostic lua require'jumpLoc'.jumpNextLocation() 
command! OpenDiagnostic lua require'jumpLoc'.openDiagnostics() 

if ! exists('g:diagnostic_enable_virtual_text')
    let g:diagnostic_enable_virtual_text = 0
endif

if ! exists('g:diagnostic_show_sign')
    let g:diagnostic_show_sign = 1
endif

if ! exists('g:diagnostic_auto_popup_while_jump')
    let g:diagnostic_auto_popup_while_jump = 1
endif

augroup DiagnosisRefresh
    autocmd!
    autocmd BufEnter * lua require'jumpLoc'.refreshBufEnter()
augroup end

augroup DiagnosisSignRefresh
    autocmd!
    autocmd InsertLeave,CursorHold * lua require'sign'.updateSign()
    autocmd InsertLeave * lua require'jumpLoc'.initLocation()
augroup end

hi DiagnosisError cterm=bold ctermfg=168 gui=bold guifg=#e06c75
sign define DiagnosisErrorSign text=✗ texthl=DiagnosisError

lua require'modify'.modifyCallback()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_diagnosis = 1
