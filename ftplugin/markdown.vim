" AUTHOR: kanno <akapanna@gmail.com>
" License: This file is placed in the public domain.

autocmd! BufWritePost <buffer> call previm#refresh()

if exists('g:loaded_previm') && g:loaded_previm
  finish
endif
let g:loaded_previm = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 PrevimOpen call previm#open(previm#make_preview_file_path('index.html'))

let &cpo = s:save_cpo
unlet! s:save_cpo
