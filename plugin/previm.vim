" AUTHOR: kanno <akapanna@gmail.com>
" License: This file is placed in the public domain.

if exists('g:loaded_previm') && g:loaded_previm
  finish
endif
let g:loaded_previm = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:change_updatetime()
  let origin = &updatetime
  let &updatetime = 500
  return origin
endfunction

function! s:setup_setting()
  augroup Previm
    if get(g:, "previm_enable_realtime", 1) !=# 0
      " NOTE: It is too frequently in TextChanged/TextChangedI
      autocmd CursorHold,CursorHoldI,InsertLeave,BufWritePost <buffer> call previm#refresh()
      autocmd BufEnter <buffer> let backup = s:change_updatetime()
      autocmd BufLeave <buffer> let &updatetime = backup
    else
      autocmd InsertLeave,BufWritePost <buffer> call previm#refresh()
    endif
  augroup END

  command! -buffer -nargs=0 PrevimOpen call previm#open(previm#make_preview_file_path('index.html'))
endfunction

augroup Previm
  autocmd!
  autocmd FileType *{mkd,markdown,rst,textile}* call <SID>setup_setting()
augroup END

let &cpo = s:save_cpo
unlet! s:save_cpo
