scriptencoding utf-8
" AUTHOR: kanno <akapanna@gmail.com>
" MAINTAINER: previm developers
" License: This file is placed in the public domain.
let s:save_cpo = &cpo
set cpo&vim

let s:newline_character = "\n"

function! previm#open(preview_html_file) abort
  let b:previm_opened = 1
  call previm#refresh()
  if exists('g:previm_open_cmd') && !empty(g:previm_open_cmd)
    if has('win32') && g:previm_open_cmd =~? 'firefox'
      " windows+firefox環境
      call s:system(g:previm_open_cmd . ' "file:///'  . fnamemodify(a:preview_html_file, ':p:gs?\\?/?g') . '"')
    elseif has('win32unix')
      call s:system(g:previm_open_cmd . ' '''  . system('cygpath -w ' . a:preview_html_file) . '''')
    elseif get(g:, 'previm_wsl_mode', 0) ==# 1
      let wsl_file_path = system('wslpath -w ' . a:preview_html_file)
      call s:system(g:previm_open_cmd . " 'file:///" . fnamemodify(wsl_file_path, ':gs?\\?\/?') . '''')
    else
      call s:system(g:previm_open_cmd . ' '''  . a:preview_html_file . '''')
    endif
  elseif s:exists_openbrowser()
    let path = a:preview_html_file
    " fix temporary(the cause unknown)
    if has('win32')
      let path = fnamemodify(path, ':p:gs?\\?/?g')
    elseif has('win32unix')
      let path = substitute(path,'\/','','')
    endif
    let path = substitute(path,' ','%20','g')
    call s:apply_openbrowser('file:///' . path)
  else
    call s:echo_err('Command for the open can not be found. show detail :h previm#open')
  endif

  augroup PrevimCleanup
    au!
    au VimLeave * call previm#wipe_cache_for_self()
  augroup END
endfunction

function! s:exists_openbrowser() abort
  try
    call openbrowser#load()
    return 1
  catch /E117.*/
    return 0
  endtry
endfunction

function! s:apply_openbrowser(path) abort
  let saved_in_vim = g:openbrowser_open_filepath_in_vim
  try
    let g:openbrowser_open_filepath_in_vim = 0
    call openbrowser#open(a:path)
  finally
    let g:openbrowser_open_filepath_in_vim = saved_in_vim
  endtry
endfunction

function! previm#refresh() abort
  if exists('b:previm_opened')
    call s:fix_preview_base_dir()
    call previm#refresh_html()
    call previm#refresh_css()
    call previm#refresh_js()
    call previm#refresh_js_function()
  endif
endfunction

function! previm#refresh_html() abort
  let lines = readfile(previm#make_preview_file_path('index.html.tmpl'))
  let output = []
  for line in lines
    if line =~# '^\s*{{previm_js_files}}'
      let indent = matchstr(line, '^\s*')
      for file in previm#assets#js()
        call add(output, printf('%s<script src="../%s"></script>', indent, file))
      endfor
    elseif line =~# '^\s*{{previm_css_files}}'
      let indent = matchstr(line, '^\s*')
      for file in previm#assets#css()
        call add(output, printf('%s<link type="text/css" href="../%s" rel="stylesheet" media="all" />', indent, file))
      endfor
   else
      call add(output, line)
    endif
  endfor

  call writefile(output, previm#make_preview_file_path('index.html'))
endfunction

let s:default_origin_css_path = "@import url('../../_/css/origin.css');"
let s:default_github_css_path = "@import url('../../_/css/lib/github.css');"

function! s:copy_dir(src, dest) abort
  if isdirectory(a:src)
    call mkdir(a:dest, 'p', 0755)
    for src in readdir(a:src)
      if !s:copy_dir(a:src .. '/' .. src, a:dest .. '/' ..  src)
        return 0
      endif
    endfor
    return 1
  elseif filereadable(a:src)
    return s:copy_file(a:src, a:dest)
  endif
endfunction

function! s:copy_file(src, dest) abort
  try
    call writefile(readfile(a:src, 'b'), a:dest, 'b')
    return 1
  catch
    return 0
  endtry
endfunction

function! previm#refresh_css() abort
  let css = []
  if get(g:, 'previm_disable_default_css', 0) !=# 1
    call extend(css, [
          \ s:default_origin_css_path,
          \ s:default_github_css_path
          \ ])
  endif
  if exists('g:previm_custom_css_path')
    let css_path = expand(g:previm_custom_css_path)
    if filereadable(css_path)
      call s:copy_file(css_path, previm#make_preview_file_path('css/user_custom.css'))
      call add(css, "@import url('user_custom.css');")
    else
      call s:echo_err('[Previm]failed load custom css. ' . css_path)
    endif
  endif

  for style in previm#assets#style()
    call add(css, style)
  endfor

  call writefile(css, previm#make_preview_file_path('css/previm.css'))
endfunction

function! previm#refresh_js() abort
  let lines = readfile(previm#make_preview_file_path('js/previm.js.tmpl'))
  let output = []
  for line in lines
    if line =~# '^\s*{{previm_init_libraries}}'
      let indent = matchstr(line, '^\s*')
      for init in previm#assets#init()
        call add(output, indent . init)
      endfor
    elseif line =~# '^\s*{{previm_load_libraries}}'
      let indent = matchstr(line, '^\s*')
      for code in previm#assets#code()
        call add(output, indent . code)
      endfor
    else
      call add(output, line)
    endif
  endfor

  call writefile(output, previm#make_preview_file_path('js/previm.js'))
endfunction

" TODO: test(refresh_cssと同じように)
function! previm#refresh_js_function() abort
  let encoded_lines = split(iconv(s:function_template(), &encoding, 'utf-8'), s:newline_character)
  call writefile(encoded_lines, previm#make_preview_file_path('js/previm-function.js'))
endfunction

let s:base_dir = fnamemodify(expand('<sfile>:p:h') . '/../preview', ':p')

function! s:fix_preview_base_dir() abort
  if !filereadable(s:preview_base_dir . '_/js/previm.js.tmpl') && s:preview_base_dir != s:base_dir
    call s:copy_dir(s:base_dir . '_', s:preview_base_dir . '_')
  endif
endfunction

if exists('g:previm_custom_preview_base_dir')
  let s:preview_base_dir = expand(g:previm_custom_preview_base_dir)
else
  let s:preview_base_dir = s:base_dir
endif

if s:preview_base_dir !~# '/$'
  let s:preview_base_dir .= '/'
endif

function! previm#preview_base_dir() abort
  return s:preview_base_dir
endfunction

function! s:preview_directory() abort
  return s:preview_base_dir . sha256(expand('%:p'))[:15] . '-' . getpid()
endfunction

function! previm#make_preview_file_path(path) abort
  let src = s:base_dir . '/_/' . a:path
  let dst = s:preview_directory() . '/' . a:path
  if !filereadable(dst)
    let dir = fnamemodify(dst, ':p:h')
	if !isdirectory(dir)
      call mkdir(dir, 'p')
    endif

    if filereadable(src)
      call s:copy_file(src, dst)
    endif
  endif
  return dst
endfunction

function! previm#cleanup_preview(dir) abort
  call delete(a:dir, 'rf')
endfunction

" NOTE: getFileType()の必要性について。
" js側でファイル名の拡張子から取得すればこの関数は不要だが、
" その場合「.txtだが内部的なファイルタイプがmarkdown」といった場合に動かなくなる。
" そのためVim側できちんとファイルタイプを返すようにしている。
function! s:function_template() abort
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
      \ 'function getOptions() {',
      \ printf('return %s;', previm#options()),
      \ '}',
      \], s:newline_character)
endfunction

function! s:get_last_modified_time() abort
  if exists('*strftime')
    return strftime('%Y/%m/%d (%a) %H:%M:%S')
  endif
  return '(strftime cannot be performed.)'
endfunction

function! s:escape_backslash(text) abort
  return escape(a:text, '\')
endfunction

function! s:system(cmd) abort
  if get(g:, 'previm_disable_vimproc', 0)
    return system(a:cmd)
  endif

  try
    " NOTE: WindowsでDOS窓を開かず実行してくれるらしいのでvimprocを使う
    let result = vimproc#system(a:cmd)
    return result
  catch /E117.*/
    return system(a:cmd)
  endtry
endfunction

function! s:do_external_parse(lines) abort
  if &filetype !=# 'rst'
    return a:lines
  endif
  " NOTE: 本来は外部コマンドに頼りたくない
  "       いずれjsパーサーが出てきたときに移行するが、
  "       その時に混乱を招かないように設定でrst2htmlへのパスを持つことはしない
  let candidates = ['rst2html.py', 'rst2html']
  let cmd = ''
  if has('win32')
    let candidates = reverse(candidates)
  endif
  for candidate in candidates
    if executable(candidate) ==# 1
      let cmd = candidate
      break
    endif
  endfor

  if empty(cmd)
    call s:echo_err('rst2html.py or rst2html has not been installed, you can not run')
    return a:lines
  endif
  let temp = tempname()
  call writefile(a:lines, temp)
  return split(s:system(cmd . ' ' . s:escape_backslash(temp)), "\n")
endfunction

function! previm#convert_to_content(lines) abort
  let mkd_dir = s:escape_backslash(expand('%:p:h'))
  if has('win32unix')
    " convert cygwin path to windows path
    let mkd_dir = substitute(system('cygpath -wa ' . mkd_dir), "\n$", '', '')
    let mkd_dir = substitute(mkd_dir, '\', '/', 'g')
  elseif get(g:, 'previm_wsl_mode', 0) ==# 1
    let mkd_dir = trim(system('wslpath -w ' . mkd_dir))
    let mkd_dir = substitute(mkd_dir, '\', '/', 'g')
  elseif has('win32')
    let mkd_dir = substitute(mkd_dir, '\', '/', 'g')
  endif
  let converted_lines = []
  for line in s:do_external_parse(a:lines)
    " TODO エスケープの理由と順番の依存度が複雑
    let escaped = substitute(line, '\', '\\\\', 'g')
    let escaped = previm#convert_relative_to_absolute_imgpath(escaped, mkd_dir)
    let escaped = substitute(escaped, '"', '\\"', 'g')
    let escaped = substitute(escaped, '\r', '\\r', 'g')
    call add(converted_lines, escaped)
  endfor
  return join(converted_lines, "\\n")
endfunction

function! previm#convert_relative_to_absolute_imgpath(text, mkd_dir) abort
  return substitute(a:text, '!\[[^\]]*\]([^)]*)', '\=previm#relative_to_absolute_imgpath(submatch(0), a:mkd_dir)', 'g')
endfunction

" convert example
" if unix:
"   ![alt](file://localhost/Users/kanno/Pictures/img.png "title")
" if win:
"   ![alt](file://localhost/C:\Documents%20and%20Settings\folder/pictures\img.png "title")
function! previm#relative_to_absolute_imgpath(text, mkd_dir) abort
  let elem = previm#fetch_imgpath_elements(a:text)
  if empty(elem.path)
    return a:text
  endif
  for protocol in ['//', 'http://', 'https://']
    if s:start_with(elem.path, protocol)
      " is absolute path
      return a:text
    endif
  endfor

  if s:is_absolute_path(elem.path)
    " ローカルの絶対パスはそのままとする
    let pre_slash = '/'
    let local_path = substitute(elem.path, ' ', '%20', 'g')
  else
    " escape backslash for substitute (see pull/#34)
    let dir = substitute(a:mkd_dir, '\\', '\\\\', 'g')
    let elem.path = substitute(elem.path, '\\', '\\\\', 'g')

    " マルチバイトの解釈はブラウザに任せるのでURLエンコードしない
    " 半角空白だけはエラーの原因になるのでURLエンコード対象とする
    let pre_slash = s:start_with(dir, '/') ? '' : '/'
    let local_path = substitute(dir.'/'.elem.path, ' ', '%20', 'g')
  endif

  let prev_imgpath = ''
  let new_imgpath = ''
  let path_prefix = '//localhost'
  if get(g:, 'previm_wsl_mode', 0) ==# 1
    let path_prefix = ''
  endif
  if s:start_with(local_path, 'file://')
    let path_prefix = ''
    let local_path = local_path[7:]
  endif
  if empty(elem.title)
    let prev_imgpath = printf('!\[%s\](%s)', elem.alt, elem.path)
    let new_imgpath = printf('![%s](%s%s%s)', elem.alt, path_prefix, pre_slash, local_path)
  else
    let prev_imgpath = printf('!\[%s\](%s "%s")', elem.alt, elem.path, elem.title)
    let new_imgpath = printf('![%s](%s%s%s "%s")', elem.alt, path_prefix, pre_slash, local_path, elem.title)
  endif

  " unify quote
  let text = substitute(a:text, "'", '"', 'g')
  return substitute(text, prev_imgpath, new_imgpath, '')
endfunction

function! previm#fetch_imgpath_elements(text) abort
  let elem = {'alt': '', 'path': '', 'title': ''}
  let matched = matchlist(a:text, '!\[\([^\]]*\)\](\([^)]*\))')
  if empty(matched)
    return elem
  endif
  let elem.alt = matched[1]
  return extend(elem, s:fetch_path_and_title(matched[2]))
endfunction

function! s:fetch_path_and_title(path) abort
  let matched = matchlist(a:path, '\(.*\)\s\+["'']\(.*\)["'']')
  if empty(matched)
    return {'path': a:path}
  endif
  let trimmed_path = matchstr(matched[1],'^\s*\zs.\{-}\ze\s*$')
  return {'path': trimmed_path, 'title': matched[2]}
endfunction

function! s:is_absolute_path(path) abort
  if has('win32')
    return tolower(substitute(a:path, '\', '/', 'g')) =~# '^/\|^[a-z]:/'
  endif
  return a:path =~ '^/'
endfunction

function! s:start_with(haystock, needle) abort
  return stridx(a:haystock, a:needle) ==# 0
endfunction

function! s:echo_err(msg) abort
  echohl WarningMsg
  echomsg a:msg
  echohl None
endfunction

function! previm#wipe_cache()
  for path in filter(split(globpath(s:preview_base_dir, '*'), "\n"), 'isdirectory(v:val) && v:val !~ "_$"')
    call previm#cleanup_preview(path)
  endfor
endfunction

function! previm#wipe_cache_for_self()
  for path in filter(split(globpath(s:preview_base_dir, '*'), "\n"), 'isdirectory(v:val) && v:val !~ "_$"')
    if path =~# '-' .. getpid() .. '$'
      call previm#cleanup_preview(path)
    endif
  endfor
endfunction

function! previm#options()
  if !exists('*json_encode')
    return '{}'
  endif
  return json_encode({
  \   'imagePrefix': get(g:, 'previm_plantuml_imageprefix', v:null),
  \   'hardLineBreak': get(b:, 'previm_hard_line_break', get(g:, 'previm_hard_line_break', v:false)),
  \   'showheader': get(g:, 'previm_show_header', 1),
  \   'autoClose': get(g:, 'previm_auto_close', 0),
  \ })
endfunction

function! previm#install() abort
  augroup Previm
    autocmd! * <buffer>
    if get(g:, 'previm_enable_realtime', 0) ==# 1
      " NOTE: It is too frequently in TextChanged/TextChangedI
      autocmd CursorHold,CursorHoldI,InsertLeave,BufWritePost <buffer> call previm#refresh()
    else
      autocmd BufWritePost <buffer> call previm#refresh()
    endif
  augroup END

  command! -buffer -nargs=0 PrevimOpen call previm#open(previm#make_preview_file_path('index.html'))
  command! -buffer -nargs=0 PrevimWipeCache call previm#wipe_cache()
  command! -buffer -nargs=0 PrevimRefresh call previm#refresh()
  command! -buffer -nargs=0 PrevimUpdateAssets call previm#assets#update()
endfunction

let &cpo = s:save_cpo
unlet! s:save_cpo
