" AUTHOR: kanno <akapanna@gmail.com>
" License: This file is placed in the public domain.
let s:save_cpo = &cpo
set cpo&vim

let s:newline_character = "\n"

function! previm#open(preview_html_file)
  call previm#refresh()
  if exists('g:previm_open_cmd') && !empty(g:previm_open_cmd)
    execute printf('silent !"%s" "%s"', g:previm_open_cmd, a:preview_html_file)
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

" NOTE: getFileType()の必要性について。
" js側でファイル名の拡張子から取得すればこの関数は不要だが、
" その場合「.txtだが内部的なファイルタイプがmarkdown」といった場合に動かなくなる。
" そのためVim側できちんとファイルタイプを返すようにしている。
function! s:function_template()
  let current_file = expand('%:p')
  return join([
      \ 'function getFileName() {',
      \ printf('return "%s";', s:escape_backslash(current_file)),
      \ '}',
      \ '',
      \ 'function getFileType() {',
      \ printf('return "%s";', &filetype),
      \ '}',
      \ '',
      \ 'function getLastModified() {',
      \ printf('return "%s";', s:get_last_modified_time()),
      \ '}',
      \ '',
      \ 'function getContent() {',
      \ printf('return "%s";', previm#convert_to_content(getline(1, '$'))),
      \ '}',
      \], s:newline_character)
endfunction

function! s:get_last_modified_time()
  if exists('*strftime')
    return strftime("%Y/%m/%d (%a) %H:%M:%S")
  endif
  return '(strftime cannot be performed.)'
endfunction

" TODO test
function! s:escape_backslash(text)
  return escape(a:text, '\')
endfunction

function! previm#convert_to_content(lines)
  let mkd_dir = s:escape_backslash(expand('%:p:h'))
  if has("win32unix")
    " convert cygwin path to windows path
    let mkd_dir = s:escape_backslash(substitute(system('cygpath -wa ' . mkd_dir), "\n$", '', ''))
  endif
  let converted_lines = []
  " TODO リストじゃなくて普通に文字列連結にする(テスト書く)
  for line in a:lines
    let escaped = substitute(line, '\', '\\\\', 'g')
    let escaped = substitute(escaped, '"', '\\"', 'g')
    let escaped = previm#relative_to_absolute_imgpath(escaped, mkd_dir)
    call add(converted_lines, escaped)
  endfor
  return join(converted_lines, "\\n")
endfunction

function! previm#relative_to_absolute_imgpath(text, mkd_dir)
  let elem = previm#fetch_imgpath_elements(a:text)
  if empty(elem.path)
    return a:text
  endif
  for protocol in ['http://', 'https://', 'file://']
    if s:start_with(elem.path, protocol)
      " is absolute path
      return a:text
    endif
  endfor

  " マルチバイトの解釈はブラウザに任せるのでURLエンコードしない
  " 半角空白だけはエラーの原因になるのでURLエンコード対象とする
  let pre_slash = s:start_with(a:mkd_dir, '/') ? '' : '/'
  let local_path = substitute(a:mkd_dir.'/'.elem.path, ' ', '%20', 'g')
  return printf('![%s](file://localhost%s%s)', elem.title, pre_slash, local_path)
endfunction

function! previm#fetch_imgpath_elements(text)
  let elem = {'title': '', 'path': ''}
  let matched = matchlist(a:text, '!\[\(.*\)\](\(.*\))')
  if empty(matched)
    return elem
  endif
  let elem.title = matched[1]
  let elem.path = matched[2]
  return elem
endfunction

function! s:start_with(haystock, needle)
  return stridx(a:haystock, a:needle) ==# 0
endfunction

let &cpo = s:save_cpo
unlet! s:save_cpo
