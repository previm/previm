" AUTHOR: kanno <akapanna@gmail.com>
" License: This file is placed in the public domain.
let s:save_cpo = &cpo
set cpo&vim

let s:newline_character = "\n"

function! previm#open(preview_html_file)
  call previm#refresh()
  if exists('g:previm_open_cmd') && !empty(g:previm_open_cmd)
    execute printf('silent !%s "%s"', g:previm_open_cmd, a:preview_html_file)
  elseif s:exists_openbrowser()
    call s:apply_openbrowser(a:preview_html_file)
  else
    echoerr 'not found command for open. show detail :h previm#open'
  endif
endfunction

function! s:exists_openbrowser()
  try
    call openbrowser#load()
    return 1
  catch /E117.*/
    return 0
  endtry
endfunction

function! s:apply_openbrowser(path)
  let saved_in_vim = g:openbrowser_open_filepath_in_vim
  try
    let g:openbrowser_open_filepath_in_vim = 0
    call openbrowser#open(a:path)
  finally
    let g:openbrowser_open_filepath_in_vim = saved_in_vim
  endtry
endfunction

function! previm#refresh()
  let encoded_lines = split(iconv(s:function_template(), &encoding, 'utf-8'), s:newline_character)
  call writefile(encoded_lines, previm#make_preview_file_path('js/previm-function.js'))
endfunction

let s:base_dir = expand('<sfile>:p:h')
function! previm#make_preview_file_path(path)
  return s:base_dir . '/../preview/' . a:path
endfunction

function! s:function_template()
  let current_file = expand('%:p')
  return join([
      \ 'function getFileName() {',
      \ printf('return "%s";', escape(current_file, '\')),
      \ '}',
      \ '',
      \ 'function getLastModified() {',
      \ printf('return "%s";', s:get_last_modified_time()),
      \ '}',
      \ '',
      \ 'function getContent() {',
      \ printf('return "%s";', s:convert_to_content(getline(1, '$'))),
      \ '}',
      \], s:newline_character)
endfunction

function! s:get_last_modified_time()
  if exists('*strftime')
    return strftime("%Y/%m/%d (%a) %H:%M:%S")
  endif
  return '(strftime cannot be performed.)'
endfunction

function! s:convert_to_content(lines)
  let converted_lines = []
  " TODO リストじゃなくて普通に文字列連結にする(テスト書く)
  for line in a:lines
    let escaped = substitute(line, '\', '\\\\\\', 'g')
    let escaped = substitute(escaped, '"', '\\"', 'g')
    call add(converted_lines, escaped)
  endfor
  return join(converted_lines, "\\n")
endfunction

let &cpo = s:save_cpo
unlet! s:save_cpo
