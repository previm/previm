scriptencoding utf-8

let s:newline = "\\n"
let s:assert = themis#helper('assert')

let s:t = themis#suite('convert_to_content') "{{{

function! s:t.empty_lines()
  let arg = []
  let expected = ''
  call s:assert.equals(previm#convert_to_content(arg), expected)
endfunction

function! s:t.not_exists_escaped()
  let arg = ['aaabbb', 'あいうえお漢字']
  let expected =
        \   'aaabbb' . s:newline
        \ . 'あいうえお漢字'
  call s:assert.equals(previm#convert_to_content(arg), expected)
endfunction

function! s:t.exists_backslash()
  let arg = ['\(x -> x + 2)', 'あいうえお漢字']
  let expected =
        \   '\\(x -> x + 2)' . s:newline
        \ . 'あいうえお漢字'
  call s:assert.equals(previm#convert_to_content(arg), expected)
endfunction

function! s:t.exists_double_quotes()
  let arg = ['he said. "Hello, john"', 'あいうえお漢字']
  let expected =
        \   'he said. \"Hello, john\"' . s:newline
        \ . 'あいうえお漢字'
  call s:assert.equals(previm#convert_to_content(arg), expected)
endfunction
"}}}
let s:t = themis#suite('wsl_open_path') "{{{

function! s:t.setup()
  let self.exists_previm_wsl_open_path_format = exists('g:previm_wsl_open_path_format')
  if self.exists_previm_wsl_open_path_format
    let self.previm_wsl_open_path_format = g:previm_wsl_open_path_format
  endif
endfunction

function! s:t.teardown()
  if self.exists_previm_wsl_open_path_format
    let g:previm_wsl_open_path_format = self.previm_wsl_open_path_format
  else
    unlet! g:previm_wsl_open_path_format
  endif
endfunction

function! s:t.default_windows_path()
  let actual = previm#wsl_open_path('/tmp/previm/index.html', 'C:\Users\me\AppData\Local\Temp\previm\index.html')
  let expected = 'file:///C:/Users/me/AppData/Local/Temp/previm/index.html'
  call s:assert.equals(actual, expected)
endfunction

function! s:t.windows_path()
  let g:previm_wsl_open_path_format = 'windows'
  let actual = previm#wsl_open_path('/tmp/previm/index.html', 'C:\Users\me\AppData\Local\Temp\previm\index.html')
  let expected = 'file:///C:/Users/me/AppData/Local/Temp/previm/index.html'
  call s:assert.equals(actual, expected)
endfunction

function! s:t.wsl_path()
  let g:previm_wsl_open_path_format = 'wsl'
  let actual = previm#wsl_open_path('/tmp/previm/index.html', 'C:\Users\me\AppData\Local\Temp\previm\index.html')
  let expected = '/tmp/previm/index.html'
  call s:assert.equals(actual, expected)
endfunction
"}}}
let s:t = themis#suite('relative_to_absolute') "{{{

function! s:t.nothing_when_empty()
  let arg_line = ''
  let expected = ''
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, ''), expected)
endfunction

function! s:t.nothing_when_not_href()
  let arg_line = 'previm.dummy.com/some/path/img.png'
  let expected = 'previm.dummy.com/some/path/img.png'
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, ''), expected)
endfunction

function! s:t.nothing_when_absolute_by_http()
  let arg_line = 'http://previm.dummy.com/some/path/img.png'
  let expected = 'http://previm.dummy.com/some/path/img.png'
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, ''), expected)
endfunction

function! s:t.nothing_when_absolute_by_https()
  let arg_line = 'https://previm.dummy.com/some/path/img.png'
  let expected = 'https://previm.dummy.com/some/path/img.png'
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, ''), expected)
endfunction

function! s:t.nothing_when_absolute_by_file()
  let arg_line = 'file://previm/some/path/img.png'
  let expected = 'file://previm/some/path/img.png'
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, ''), expected)
endfunction

function! s:t.replace_path_when_relative()
  let rel_path = 'previm/some/path/img.png'
  let arg_line = printf('![img](%s)', rel_path)
  let arg_dir = '/Users/foo/tmp'
  let expected = printf('![img](//localhost%s/%s)', arg_dir, rel_path)
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, arg_dir), expected)
endfunction

function! s:t.urlencoded_path()
  let rel_path = 'previm\some\path\img.png'
  let arg_line = printf('![img](%s)', rel_path)
  let arg_dir = 'C:\Documents and Settings\folder'
  let expected = '![img](//localhost/C:\Documents%20and%20Settings\folder/previm\some\path\img.png)'
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, arg_dir), expected)
endfunction

function! s:t.with_title_from_double_quote()
  let rel_path = 'previm\some\path\img.png'
  let arg_line = printf('![img](%s "title")', rel_path)
  let arg_dir = 'C:\Documents and Settings\folder'
  let expected = '![img](//localhost/C:\Documents%20and%20Settings\folder/previm\some\path\img.png "title")'
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, arg_dir), expected)
endfunction

function! s:t.with_title_from_single_quote()
  let rel_path = 'previm\some\path\img.png'
  let arg_line = printf("![img](%s 'title')", rel_path)
  let arg_dir = 'C:\Documents and Settings\folder'
  let expected = '![img](//localhost/C:\Documents%20and%20Settings\folder/previm\some\path\img.png "title")'
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, arg_dir), expected)
endfunction

function! s:t.not_only_img()
  let rel_path = 'previm/some/path/img.png'
  let arg_line = printf('| a | ![img](%s) |', rel_path)
  let arg_dir  = '/Users/foo/tmp'
  let expected = printf('| a | ![img](//localhost%s/%s) |', arg_dir, rel_path)
  call s:assert.equals(previm#relative_to_absolute_filepath(arg_line, arg_dir), expected)
endfunction
"}}}
let s:t = themis#suite('url_path_mappings') "{{{

function! s:t.setup()
  let self.cwd = getcwd()
  let self.tmp = substitute(resolve(tempname()), '[\/]$', '', '')
  call mkdir(self.tmp, 'p')

  let self.exists_global_mappings = exists('g:previm_url_path_mappings')
  if self.exists_global_mappings
    let self.global_mappings = g:previm_url_path_mappings
  endif

  let self.exists_buffer_mappings = exists('b:previm_url_path_mappings')
  if self.exists_buffer_mappings
    let self.buffer_mappings = b:previm_url_path_mappings
  endif

  let self.exists_wsl_mode = exists('g:previm_wsl_mode')
  if self.exists_wsl_mode
    let self.wsl_mode = g:previm_wsl_mode
  endif
endfunction

function! s:t.teardown()
  execute 'lcd' fnameescape(self.cwd)
  call delete(self.tmp, 'rf')

  if self.exists_global_mappings
    let g:previm_url_path_mappings = self.global_mappings
  else
    unlet! g:previm_url_path_mappings
  endif

  if self.exists_buffer_mappings
    let b:previm_url_path_mappings = self.buffer_mappings
  else
    unlet! b:previm_url_path_mappings
  endif

  if self.exists_wsl_mode
    let g:previm_wsl_mode = self.wsl_mode
  else
    unlet! g:previm_wsl_mode
  endif
endfunction

function! s:t.resolve_with_cwd_placeholder()
  call mkdir(self.tmp . '/public/assets', 'p')
  call writefile([], self.tmp . '/public/assets/example.png')
  execute 'lcd' fnameescape(self.tmp)
  let g:previm_url_path_mappings = {'/assets/': '{cwd}/public/assets/'}

  let actual = previm#resolve_url_path_mapping('/assets/example.png')
  let expected = getcwd() . '/public/assets/example.png'
  call s:assert.equals(actual, expected)
endfunction

function! s:t.resolve_buffer_mapping_before_global_mapping()
  call mkdir(self.tmp . '/global/images', 'p')
  call mkdir(self.tmp . '/buffer/images', 'p')
  call writefile([], self.tmp . '/global/images/example.png')
  call writefile([], self.tmp . '/buffer/images/example.png')
  let g:previm_url_path_mappings = {'/images/': self.tmp . '/global/images/'}
  let b:previm_url_path_mappings = {'/images/': self.tmp . '/buffer/images/'}

  let actual = previm#resolve_url_path_mapping('/images/example.png')
  let expected = self.tmp . '/buffer/images/example.png'
  call s:assert.equals(actual, expected)
endfunction

function! s:t.resolve_with_gitroot_placeholder()
  call mkdir(self.tmp . '/.git', 'p')
  call mkdir(self.tmp . '/articles', 'p')
  call mkdir(self.tmp . '/images', 'p')
  call writefile([], self.tmp . '/articles/example.md')
  call writefile([], self.tmp . '/images/example.png')
  execute 'edit' fnameescape(self.tmp . '/articles/example.md')
  let g:previm_url_path_mappings = {'/images/': '{gitroot}/images/'}

  let actual = previm#resolve_url_path_mapping('/images/example.png')
  let expected = self.tmp . '/images/example.png'
  call s:assert.equals(actual, expected)
endfunction

function! s:t.rewrite_root_relative_image_with_mapping()
  call mkdir(self.tmp . '/images', 'p')
  call writefile([], self.tmp . '/images/example.png')
  let g:previm_url_path_mappings = {'/images/': self.tmp . '/images/'}

  let actual = previm#relative_to_absolute_filepath('![img](/images/example.png)', '')
  let pre_slash = self.tmp =~# '^/' ? '' : '/'
  let expected = printf('![img](//localhost%s%s/images/example.png)', pre_slash, self.tmp)
  call s:assert.equals(actual, expected)
endfunction

function! s:t.convert_mapped_path_for_wsl_mode()
  let g:previm_wsl_mode = 1

  let actual = previm#url_path_mapping_local_path('/home/me/repo/images/example.png', 'C:\Users\me\repo\images\example.png')
  let expected = 'C:/Users/me/repo/images/example.png'
  call s:assert.equals(actual, expected)
endfunction
"}}}
let s:t = themis#suite('fetch_filepath_elements') "{{{

function! s:t.nothing_when_empty()
  let arg = ''
  let expected = s:empty_img_elements()
  call s:assert.equals(previm#fetch_filepath_elements(arg), expected)
endfunction

function! s:t.nothing_when_not_img_statement()
  let arg = '## hogeほげ'
  let expected = s:empty_img_elements()
  call s:assert.equals(previm#fetch_filepath_elements(arg), expected)
endfunction

function! s:t.get_alt_and_path()
  let arg = '![IMG](path/img.png)'
  let expected = {'type': 'img', 'alt': 'IMG', 'path': 'path/img.png', 'title': ''}
  call s:assert.equals(previm#fetch_filepath_elements(arg), expected)
endfunction

function! s:t.get_alt_and_path_from_image_in_link()
  let arg = '[![IMG](path/img.png)](path/some/file)'
  let expected1 = {'type': 'link', 'alt': '![IMG](path/img.png)', 'path': 'path/some/file', 'title': ''}
  let expected2 = {'type': 'img', 'alt': 'IMG', 'path': 'path/img.png', 'title': ''}
  let ret1 = previm#fetch_filepath_elements(arg)
  let ret2 = previm#fetch_filepath_elements(ret1.alt)
  call s:assert.equals(ret1, expected1)
  call s:assert.equals(ret2, expected2)
endfunction

function! s:t.get_title_from_double_quote()
  let arg = '![IMG](path/img.png  "image")'
  let expected = {'type': 'img', 'alt': 'IMG', 'path': 'path/img.png', 'title': 'image'}
  call s:assert.equals(expected, previm#fetch_filepath_elements(arg))
endfunction

function! s:t.get_title_from_single_quote()
  let arg = "![IMG](path/img.png  'image')"
  let expected = {'type': 'img', 'alt': 'IMG', 'path': 'path/img.png', 'title': 'image'}
  call s:assert.equals(expected, previm#fetch_filepath_elements(arg))
endfunction

function! s:empty_img_elements()
  return {'type': '', 'alt': '', 'path': '', 'title': ''}
endfunction
"}}}
let s:t = themis#suite('refresh_css') "{{{
function! s:t.setup()
  let self.exist_previm_disable_default_css = 0
  if exists('g:previm_disable_default_css')
    let self.tmp_previm_disable_default_css = g:previm_disable_default_css
    let self.exist_previm_disable_default_css = 1
  endif

  let self.exist_previm_custom_css_path = 0
  if exists('g:previm_custom_css_path')
    let self.tmp_previm_custom_css_path = g:previm_custom_css_path
    let self.exist_previm_custom_css_path = 1
  endif
endfunction

function! s:t.teardown()
  if self.exist_previm_disable_default_css
    let g:previm_disable_default_css = self.tmp_previm_disable_default_css
  else
    unlet! g:previm_disable_default_css
  endif

  if self.exist_previm_custom_css_path
    let g:previm_custom_css_path = self.tmp_previm_custom_css_path
  else
    unlet! g:previm_custom_css_path
  endif
endfunction

let s:default_origin_css_path = "@import url('../../_/css/origin.css') layer;"
let s:default_github_css_path = "@import url('../../_/css/lib/github.css') layer;"
function! s:t.default_content_if_not_exists_setting()
  call previm#refresh_css()
  let actual = readfile(previm#make_preview_file_path('css/previm.css'))
  call s:assert.equals([
        \ s:default_origin_css_path,
        \ s:default_github_css_path
        \ ], actual)
endfunction

function! s:t.default_content_if_invalid_setting()
  let g:previm_disable_default_css = 2
  if exists('g:previm_custom_css_path')
    unlet g:previm_custom_css_path
  endif
  call previm#refresh_css()
  let actual = readfile(previm#make_preview_file_path('css/previm.css'))
  call s:assert.equals([
        \ s:default_origin_css_path,
        \ s:default_github_css_path,
        \ ], actual)
endfunction

let s:base_dir = expand('<sfile>:p:h')
function! s:t.custom_content_if_exists_file()
  let g:previm_disable_default_css = 1
  let g:previm_custom_css_path = s:base_dir . '/dummy_user_custom.css'
  call previm#refresh_css()

  let actual = readfile(previm#make_preview_file_path('css/previm.css'))
  call s:assert.equals(actual, ["@import url('user_custom.css');"])
endfunction

function! s:t.empty_if_not_exists_file()
  let g:previm_disable_default_css = 1
  let g:previm_custom_css_path = s:base_dir . '/not_exists.css'
  call previm#refresh_css()

  let actual = readfile(previm#make_preview_file_path('css/previm.css'))
  call s:assert.equals(actual, [])
endfunction
"}}}
"

let s:t = themis#suite('assets_missing') "{{{

function! s:t.teardown()
  unlet! g:previm_extra_libraries
endfunction

function! s:t.empty_if_no_extra_libraries()
  unlet! g:previm_extra_libraries
  call s:assert.equals(previm#assets#missing(), [])
endfunction

function! s:t.returns_only_missing_enabled_files()
  let g:previm_extra_libraries = [
        \ {'name': 'exists', 'files': [{'type': 'js', 'path': '_/js/lib/markdown-it.min.js'}]},
        \ {'name': 'missing', 'files': [
        \   {'type': 'js', 'path': '_/js/extra/not_exists.js'},
        \   {'type': 'js', 'init': ['md.options.typographer = true;']},
        \ ]},
        \ {'name': 'disabled', 'enabled': v:false, 'files': [{'type': 'js', 'path': '_/js/extra/disabled.js'}]},
        \ ]
  call s:assert.equals(previm#assets#missing(), ['_/js/extra/not_exists.js'])
endfunction
"}}}
