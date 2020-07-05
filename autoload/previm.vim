scriptencoding utf-8
" AUTHOR: kanno <akapanna@gmail.com>
" MAINTAINER: previm developers
" License: This file is placed in the public domain.
let s:save_cpo = &cpo
set cpo&vim

let s:File = vital#previm#import('System.File')

let s:newline_character = "\n"
let s:bookdir = "_build"

function! previm#open(preview_html_file) abort
  call previm#refresh()
  if exists('g:previm_open_cmd') && !empty(g:previm_open_cmd)
    if has('win32') && g:previm_open_cmd =~? 'firefox'
      " windows+firefox環境
      call s:system(g:previm_open_cmd . ' "file:///'  . fnamemodify(a:preview_html_file, ':p:gs?\\?/?g') . '"')
    elseif has('win32unix')
      call s:system(g:previm_open_cmd . ' '''  . system('cygpath -w ' . a:preview_html_file) . '''')
    elseif get(g:, 'previm_wsl_mode', 0) ==# 1
      let l:wsl_file_path = system('wslpath -w ' . a:preview_html_file)
      call s:system(g:previm_open_cmd . " 'file:///" . fnamemodify(l:wsl_file_path, ':gs?\\?\/?') . '''')
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
endfunction

function! previm#open1() abort
  let b:refresh_mode = 1
  call previm#open(previm#make_preview_file_path('index.html'))
endfunction

function! previm#open2() abort
  let b:refresh_mode = 2
  if !isdirectory(s:preview_base_directory() . '_')
    call s:File.copy_dir(s:base_dir . 'local_', s:preview_directory())
  endif
  call previm#open(previm#make_preview_file_path('index.html'))
endfunction

function! previm#book() abort
  let b:refresh_mode = 3
  let l:root = s:rootpath()
  let l:bookdir = "/" . s:bookdir
  if !isdirectory(l:root . l:bookdir)
    call s:File.copy_dir(s:base_dir . 'book_', l:root . l:bookdir)
  endif
  call s:book_nodes(l:root)
  call previm#open(l:root . l:bookdir . '/index.html')
endfunction

function! previm#patchdir() abort
  let l:previm_mode = get(b:, 'refresh_mode', 0)
  if l:previm_mode == 2
    let l:rootdir = s:preview_directory()
  elseif l:previm_mode == 3
    let l:rootdir = s:rootpath() . "/" . s:bookdir
  else
    let l:rootdir = ''
  endif
  let l:setting = substitute(input("Custom setting file: ", l:rootdir, "file"), '\', '/', 'g')
  let l:rootdir = substitute(input("Root dir: ", l:rootdir, "dir"), '\', '/', 'g')
  if isdirectory(l:rootdir) && filereadable(l:setting)
    if strpart(l:rootdir, len(l:rootdir) - 1) != '/'
      let l:rootdir = l:rootdir . '/'
    endif
    let l:pat01 = '===================='
    let l:pat02 = '--------------------'
    let l:file1 = l:rootdir . 'index.html'
    let l:file2 = l:rootdir . 'js/previm.js'
    let l:pat11 = '<!-- Custom JS Start -->'
    let l:pat12 = '<!-- Custom JS End -->'
    let l:pat21 = '/* markdownitContainer Start */'
    let l:pat22 = '/* markdownitContainer End */'
    let l:pat23 = '/* Custom Render Start */'
    let l:pat24 = '/* Custom Render End */'
    let l:lines = readfile(l:setting)
    let l:pos1 = index(l:lines, l:pat01)
    let l:pos2 = index(l:lines, l:pat02)
    let l:replace22 = remove(l:lines, l:pos2 + 1, len(l:lines) - 1)
    let l:replace21 = remove(l:lines, l:pos1 + 1, l:pos2 - 1)
    let l:replace11 = remove(l:lines, 0, l:pos1 - 1)

    let l:lines = readfile(l:file1)
    let l:pos1 = index(l:lines, l:pat11)
    let l:pos2 = index(l:lines, l:pat12)
    if (l:pos1 >= 0) && (l:pos2 >= 0)
      if l:pos2 - l:pos1 > 1
        call remove(l:lines, l:pos1 + 1, l:pos2 - 1)
      endif
      let l:pos2 = l:pos1 + 1
      for l:item in l:replace11
        call insert(l:lines, l:item, l:pos2)
        let l:pos2 = l:pos2 + 1
      endfor
      call writefile(l:lines, l:file1)
    endif

    let l:lines = readfile(l:file2)
    let l:pos1 = index(l:lines, l:pat23)
    let l:pos2 = index(l:lines, l:pat24)
    if (l:pos1 >= 0) && (l:pos2 >= 0)
      if l:pos2 - l:pos1 > 1
        call remove(l:lines, l:pos1 + 1, l:pos2 - 1)
      endif
      let l:pos2 = l:pos1 + 1
      for l:item in l:replace22
        call insert(l:lines, l:item, l:pos2)
        let l:pos2 = l:pos2 + 1
      endfor
    endif
    let l:pos1 = index(l:lines, l:pat21)
    let l:pos2 = index(l:lines, l:pat22)
    if (l:pos1 >= 0) && (l:pos2 >= 0)
      if l:pos2 - l:pos1 > 1
        call remove(l:lines, l:pos1 + 1, l:pos2 - 1)
      endif
      let l:pos2 = l:pos1 + 1
      for l:item in l:replace21
        call insert(l:lines, l:item, l:pos2)
        let l:pos2 = l:pos2 + 1
      endfor
    endif
    call writefile(l:lines, l:file2)
  endif
endfunction

function! s:book_nodes(root) abort
  let l:bookdir = "/" . s:bookdir
  let l:contentpath = "js/out/"
  let l:filelist = globpath(a:root, "**/*.{markdown,mdown,mkd,mkdn,mdwn,md,rst}", 0, 1)
  let l:skiplen = strlen(a:root) + 1
  let l:sep = strpart(l:filelist[0], l:skiplen-1, 1)
  let l:idx = 1
  let l:basedirs = []
  let l:outtxt = ["const treenodes = ["]
  if !isdirectory(a:root . l:bookdir . "/" . l:contentpath)
    call mkdir(a:root . l:bookdir . "/" . l:contentpath, 'p')
  endif
  for l:item in l:filelist
    if has('win32unix')
      " convert cygwin path to windows path
      let l:item = substitute(system('cygpath -wa ' . l:item), "\n$", '', '')
      let l:item = substitute(l:item, '\', '/', 'g')
    elseif has('win32')
      let l:item = substitute(l:item, '\', '/', 'g')
    endif
    let l:relitem = strpart(l:item, l:skiplen)
    let l:parts = split(l:relitem, '/')
    if len(l:parts) > 1
        if l:parts[0] == s:bookdir
            continue
        elseif strpart(l:parts[0], 0, 1) == '_'
            continue
        endif
    endif
    let l:j = 0
    let l:fprefix = 0
    while l:j < len(l:parts) - 1
        if l:fprefix == 0
            if l:j >= len(l:basedirs)
                let l:fprefix = 1
                call add(l:outtxt, repeat("  ", l:j+1) . "{ id: " . l:idx . ", name: '" . l:parts[l:j] . "', children: [")
                let l:idx = l:idx + 1
            else
                if l:basedirs[l:j] != l:parts[l:j]
                    let l:fprefix = 1
                    let l:k = len(l:basedirs)
                    while l:k > l:j
                        call add(l:outtxt, repeat("  ", l:k+1) . "],")
                        let l:k = l:k - 1
                        call add(l:outtxt, repeat("  ", l:k+1) . "},")
                    endwhile
                    call add(l:outtxt, repeat("  ", l:j+1) . "{ id: " . l:idx . ", name: '" . l:parts[l:j] . "', children: [")
                    let l:idx = l:idx + 1
                endif
            endif
        else
            call add(l:outtxt, repeat("  ", l:j+1) . "{ id: " . l:idx . ", name: '" . l:parts[l:j] . "', children: [")
            let l:idx = l:idx + 1
        endif
        let l:j = l:j + 1
    endwhile
    let l:targetfile = l:contentpath . sha256(l:relitem)[:15] . ".js"
    call add(l:outtxt, repeat("  ", l:j+1) . "{ id: " . l:idx . ", name: '" . l:parts[l:j] . "', doc: '" . l:targetfile . "' },")
    if getftime(l:item) > getftime(a:root . l:bookdir . "/" . l:targetfile)
        if bufexists(l:item)
            silent! exe "b " . bufnr(l:item)
            let l:encoded_lines = split(iconv(s:function_template(), &encoding, 'utf-8'), s:newline_character)
            call writefile(encoded_lines, a:root . l:bookdir . "/" . l:targetfile)
        else
            silent! exe "edit ". l:item
            let l:encoded_lines = split(iconv(s:function_template(), &encoding, 'utf-8'), s:newline_character)
            call writefile(encoded_lines, a:root . l:bookdir . "/" . l:targetfile)
            silent! exe "bdelete"
        endif
    endif
    let l:idx = l:idx + 1
    if l:fprefix > 0
        let l:basedirs = copy(l:parts)
        call remove(l:basedirs, -1)
    endif
  endfor
  let l:k = len(l:basedirs)
  while l:k > 0
      call add(l:outtxt, repeat("  ", l:k+1) . "],")
      let l:k = l:k - 1
      call add(l:outtxt, repeat("  ", l:k+1) . "},")
  endwhile
  call add(l:outtxt, "]")
  call writefile(l:outtxt, a:root . l:bookdir . "/" . l:contentpath . "nodes.js")
endfunction

function! s:exists_openbrowser() abort
  try
    if get(g:, 'spacevim_plugin_manager', '') ==# 'dein'
      if get(dein#get('open-browser.vim'), 'sourced', 0) == 0
        call dein#source('open-browser.vim')
      endif
    endif
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
  let l:previm_mode = get(b:, 'refresh_mode', 0)
  if l:previm_mode <= 0
    return
  elseif l:previm_mode <= 2
    call previm#refresh_css()
    call previm#refresh_js()
  else
    let l:bookdir = "/" . s:bookdir
    let l:contentpath = "js/out/"
    let l:root = s:rootpath()
    let l:skiplen = strlen(l:root) + 1
    let l:sep = "/"
    let l:item = expand("%:p")
    if has('win32unix')
      " convert cygwin path to windows path
      let l:item = substitute(system('cygpath -wa ' . l:item), "\n$", '', '')
      let l:item = substitute(l:item, '\', '/', 'g')
    elseif has('win32')
      let l:item = substitute(l:item, '\', '/', 'g')
    endif
    let l:relitem = strpart(l:item, l:skiplen)
    let l:targetfile = l:contentpath . sha256(l:relitem)[:15] . ".js"
    let encoded_lines = split(iconv(s:function_template(), &encoding, 'utf-8'), s:newline_character)
    call writefile(encoded_lines, l:root . l:bookdir . "/" . l:targetfile)
  endif
endfunction

let s:default_origin_css_path = "@import url('../../_/css/origin.css');"
let s:default_github_css_path = "@import url('../../_/css/lib/github.css');"
let s:local_origin_css_path = "@import url('origin.css');"
let s:local_github_css_path = "@import url('lib/github.css');"

function! previm#refresh_css() abort
  let css = []
  if get(g:, 'previm_disable_default_css', 0) !=# 1
    let l:previm_mode = get(b:, 'refresh_mode', 0)
    if l:previm_mode == 1
      call extend(css, [
            \ s:default_origin_css_path,
            \ s:default_github_css_path
            \ ])
    elseif l:previm_mode == 2
      call extend(css, [
            \ s:local_origin_css_path,
            \ s:local_github_css_path
            \ ])
    endif
  endif
  if exists('g:previm_custom_css_path')
    let css_path = expand(g:previm_custom_css_path)
    if filereadable(css_path)
      call s:File.copy(css_path, previm#make_preview_file_path('css/user_custom.css'))
      call add(css, "@import url('user_custom.css');")
    else
      call s:echo_err('[Previm]failed load custom css. ' . css_path)
    endif
  endif
  call writefile(css, previm#make_preview_file_path('css/previm.css'))
endfunction

" TODO: test(refresh_cssと同じように)
function! previm#refresh_js() abort
  let encoded_lines = split(iconv(s:function_template(), &encoding, 'utf-8'), s:newline_character)
  call writefile(encoded_lines, previm#make_preview_file_path('js/previm-function.js'))
endfunction

let s:base_dir = fnamemodify(expand('<sfile>:p:h') . '/../preview', ':p')

function! s:preview_base_directory() abort
  let l:previm_mode = get(b:, 'refresh_mode', 0)
  if l:previm_mode == 1
    return s:base_dir
  elseif l:previm_mode == 2
    return fnamemodify(expand('%:p:h'), ':p')
  else
    return ""
  endif
endfunction

function! s:preview_directory() abort
  return s:preview_base_directory() . sha256(expand('%:p'))[:15] . '-' . getpid()
endfunction

function! previm#make_preview_file_path(path) abort
  let l:previm_mode = get(b:, 'refresh_mode', 0)
  let src = s:preview_base_directory() . '/_/' . a:path
  let dst = s:preview_directory() . '/' . a:path
  if !filereadable(dst)
    let dir = fnamemodify(dst, ':p:h')
    if !isdirectory(dir)
      call mkdir(dir, 'p')
    endif

    if l:previm_mode <= 1
      augroup PrevimCleanup
        au!
        exe printf("au VimLeave * call previm#cleanup_preview('%s')", dir)
      augroup END
    endif
    if filereadable(src)
      call s:File.copy(src, dst)
    endif
  endif
  return dst
endfunction

function! previm#cleanup_preview(dir) abort
  if isdirectory(a:dir)
    try
      call s:File.rmdir(a:dir, 'r')
    catch
    endtry
  endif
endfunction

" NOTE: getFileType()の必要性について。
" js側でファイル名の拡張子から取得すればこの関数は不要だが、
" その場合「.txtだが内部的なファイルタイプがmarkdown」といった場合に動かなくなる。
" そのためVim側できちんとファイルタイプを返すようにしている。
function! s:function_template() abort
  let current_file = expand('%:p')
  return join([
      \ 'function isShowHeader() {',
      \ printf('return %s;', get(g:, 'previm_show_header', 1)),
      \ '}',
      \ '',
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

function! s:expand_include(lines, fpath) abort
  let l:i = 0
  let l:lines = []
  let l:previm_mode = get(b:, 'refresh_mode', 0)
  while l:i < len(a:lines)
    let l:pos = match(a:lines[l:i], "{%\\s\\+include\\s\\+\\(.\\{-2,}\\)\\s\\+%}")
    if l:pos >= 0
      let l:parts = matchlist(a:lines[l:i], "{%\\s\\+include\\s\\+\\(.\\{-2,}\\)\\s\\+%}")
      let l:relpath = strpart(l:parts[1], 1, len(l:parts[1]) - 2)
      if l:previm_mode == 3
        if strpart(l:relpath[0], 0, 1) == '/'
          let l:fullpath = s:rootpath() . l:relpath
        else
          let l:fullpath = fnamemodify(fnamemodify(a:fpath, ':h') . '/' . l:relpath, ':p')
        endif
      else
        let l:fullpath = fnamemodify(fnamemodify(a:fpath, ':h') . '/' . l:relpath, ':p')
      endif
      if filereadable(l:fullpath)
        let l:lines2 = readfile(l:fullpath)
        let l:inner = s:expand_include(l:lines2, l:fullpath)
        let l:inner[0] =  strpart(a:lines[l:i], 0, l:pos) . l:inner[0]
        let l:inner[-1] = l:inner[-1] . strpart(a:lines[l:i], l:pos + len(l:parts[0]))
        call extend(l:lines, l:inner)
      else
        call add(l:lines, a:lines[l:i])
      endif
    else
      call add(l:lines, a:lines[l:i])
    endif
    let l:i = l:i + 1
  endwhile
  return l:lines
endfunction

function! s:do_external_parse(lines) abort
  if &filetype !=# 'rst'
    return s:expand_include(a:lines, expand('%:p'))
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
  if has('win32')
    return split(s:system('python ' . exepath(cmd) . ' ' . s:escape_backslash(temp)), "\n")
  else
    return split(s:system(cmd . ' ' . s:escape_backslash(temp)), "\n")
  endif
endfunction

function! previm#convert_to_content(lines) abort
  let mkd_dir = s:escape_backslash(expand('%:p:h'))
  if has('win32unix')
    " convert cygwin path to windows path
    let mkd_dir = substitute(system('cygpath -wa ' . mkd_dir), "\n$", '', '')
    let mkd_dir = substitute(mkd_dir, '\', '/', 'g')
  elseif has('win32')
    let mkd_dir = substitute(mkd_dir, '\', '/', 'g')
  endif
  let converted_lines = []
  for line in s:do_external_parse(a:lines)
    " TODO エスケープの理由と順番の依存度が複雑
    let escaped = substitute(line, '\', '\\\\', 'g')
    let escaped = previm#relative_to_absolute_imgpath(escaped, mkd_dir)
    let escaped = substitute(escaped, '"', '\\"', 'g')
    let escaped = substitute(escaped, '\r', '\\r', 'g')
    call add(converted_lines, escaped)
  endfor
  return join(converted_lines, "\\n")
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
  if s:start_with(local_path, 'file://')
    let path_prefix = ''
    let local_path = local_path[7:]
  endif
  if path_prefix != ''
    let l:previm_mode = get(b:, 'refresh_mode', 0)
    let l:simple = substitute(local_path, '//', '/', 'g')
    if l:previm_mode == 2
        let l:previm_dir = s:preview_directory() . '/assets'
        if !isdirectory(l:previm_dir)
          call mkdir(l:previm_dir, 'p')
        endif
        let path_prefix = "assets"
        let pre_slash = "/"
        let local_path = split(l:simple, '/')[-1]
        if getftime(l:simple) > getftime(l:previm_dir . "/" . local_path)
          call s:File.copy(l:simple, l:previm_dir . "/" . local_path)
        endif
    elseif l:previm_mode == 3
      let l:root = s:rootpath() . "/"
      if s:start_with(l:simple, l:root)
        let path_prefix = ".."
        let pre_slash = "/"
        let local_path = strpart(l:simple, strlen(l:root))
      endif
    endif
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
    return tolower(substitute(a:path, '\', '/', 'g')) =~ '^/\|^[a-z]:/'
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
  for path in filter(split(globpath(s:base_dir, '*'), "\n"), 'isdirectory(v:val) && v:val !~ "_$"')
    call previm#cleanup_preview(path)
  endfor
  let l:previm_mode = get(b:, 'refresh_mode', 0)
  if l:previm_mode == 2
    call previm#cleanup_preview(s:preview_directory())
  elseif l:previm_mode == 3
    let l:root = s:rootpath()
    let l:bookdir = "/" . s:bookdir
    call previm#cleanup_preview(l:root . l:bookdir)
  endif
  let b:refresh_mode = 0
endfunction

function! previm#options()
  if !exists('*json_encode')
    return '{}'
  endif
  return json_encode({
  \   'plantuml_imageprefix': get(g:, 'previm_plantuml_imageprefix', v:null)
  \ })
endfunction

func! s:rootpath(...)
    let l:rootpattern = [".git", ".svn", ".root"]
    if a:0 > 0
        let l:rootpattern = l:rootpattern + a:1
    endif
    let l:curpath = expand("%:p:h")
    while 1
        for l:item in readdir(l:curpath)
            if index(l:rootpattern, l:item) >= 0
                if has('win32unix')
                  " convert cygwin path to windows path
                  let l:curpath = substitute(system('cygpath -wa ' . l:curpath), "\n$", '', '')
                  let l:curpath = substitute(l:curpath, '\', '/', 'g')
                elseif has('win32')
                  let l:curpath = substitute(l:curpath, '\', '/', 'g')
                endif
                return l:curpath
            endif
        endfor
        let l:newpath = fnamemodify(l:curpath, ":h")
        if l:newpath == l:curpath
            return ""
        else
            let l:curpath = l:newpath
        endif
    endwhile
endf

let &cpo = s:save_cpo
unlet! s:save_cpo
