" AUTHOR: kanno <akapanna@gmail.com>
" License: This file is placed in the public domain.
let s:save_cpo = &cpo
set cpo&vim

function! previm#open(preview_html_file)
  call previm#refresh()
  execute printf('silent !open -a Safari "%s"', a:preview_html_file)
  "call openbrowser#open(s:preview_html_file)
endfunction

function! previm#refresh()
  let function_js_file = previm#make_preview_file_path('js/previm-function.js')
  if filewritable(function_js_file) !=# 1
    throw function_js_file . ' cannot be created.'
  endif
  call writefile(s:function_template(), function_js_file)
endfunction

let s:base_dir = expand('<sfile>:p:h')
function! previm#make_preview_file_path(path)
  return s:base_dir . '/../preview/' . a:path
endfunction

function! s:function_template()
  let current_file = expand('%:p')
  return [
      \ 'function getFileName() {',
      \ printf('return "%s";', current_file),
      \ '}',
      \ '',
      \ 'function getLastModified() {',
      \ printf('return "%s";', strftime("%Y/%m/%d (%a) %H:%M")),
      \ '}',
      \ '',
      \ 'function getContent() {',
      \ printf('return "%s";', s:convert_to_content(getline(1, '$'))),
      \ '}',
      \]
endfunction

function! s:convert_to_content(lines)
  let converted_lines = []
  for line in a:lines
    let escaped = substitute(line, '\', '\\\\\\', 'g')
    let escaped = substitute(escaped, '"', '\\"', 'g')
    call add(converted_lines, escaped)
  endfor
  return join(converted_lines, "\\n")
endfunction

let &cpo = s:save_cpo
unlet! s:save_cpo
