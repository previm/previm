let s:newline = "\\n"

let s:t = vimtest#new('convert_to_content') "{{{

function! s:t.empty_lines()
  let arg = []
  let expected = ''
  call self.assert.equals(expected, previm#convert_to_content(arg))
endfunction

function! s:t.not_exists_escaped()
  let arg = ['aaabbb', 'あいうえお漢字']
  let expected = 
        \   'aaabbb' . s:newline
        \ . 'あいうえお漢字'
  call self.assert.equals(expected, previm#convert_to_content(arg))
endfunction

function! s:t.exists_backslash()
  let arg = ['\(x -> x + 2)', 'あいうえお漢字']
  let expected =
        \   '\\\(x -> x + 2)' . s:newline
        \ . 'あいうえお漢字'
  call self.assert.equals(expected, previm#convert_to_content(arg))
endfunction

function! s:t.exists_double_quotes()
  let arg = ['he said. "Hello, john"', 'あいうえお漢字']
  let expected =
        \   'he said. \"Hello, john\"' . s:newline
        \ . 'あいうえお漢字'
  call self.assert.equals(expected, previm#convert_to_content(arg))
endfunction
"}}}
let s:t = vimtest#new('relative_to_absolute') "{{{

function! s:t.nothing_when_empty()
  let arg_line = ''
  let expected = ''
  call self.assert.equals(expected, previm#relative_to_absolute_imgpath(arg_line, ''))
endfunction

function! s:t.nothing_when_not_href()
  let arg_line = 'previm.dummy.com/some/path/img.png'
  let expected = 'previm.dummy.com/some/path/img.png'
  call self.assert.equals(expected, previm#relative_to_absolute_imgpath(arg_line, ''))
endfunction

function! s:t.nothing_when_absolute_by_http()
  let arg_line = 'http://previm.dummy.com/some/path/img.png'
  let expected = 'http://previm.dummy.com/some/path/img.png'
  call self.assert.equals(expected, previm#relative_to_absolute_imgpath(arg_line, ''))
endfunction

function! s:t.nothing_when_absolute_by_https()
  let arg_line = 'https://previm.dummy.com/some/path/img.png'
  let expected = 'https://previm.dummy.com/some/path/img.png'
  call self.assert.equals(expected, previm#relative_to_absolute_imgpath(arg_line, ''))
endfunction

function! s:t.nothing_when_absolute_by_file()
  let arg_line = 'file://previm/some/path/img.png'
  let expected = 'file://previm/some/path/img.png'
  call self.assert.equals(expected, previm#relative_to_absolute_imgpath(arg_line, ''))
endfunction

function! s:t.replace_path_when_relative()
  let rel_path = 'previm/some/path/img.png'
  let arg_line = printf('![img](%s)', rel_path)
  let arg_dir = '/Users/foo/tmp'
  let expected = printf('![img](file://localhost%s/%s)', arg_dir, rel_path)
  call self.assert.equals(expected, previm#relative_to_absolute_imgpath(arg_line, arg_dir))
endfunction

function! s:t.urlencoded_path()
  let rel_path = 'previm\some\path\img.png'
  let arg_line = printf('![img](%s)', rel_path)
  let arg_dir = 'C:\Documents and Settings\folder'
  let expected = '![img](file://localhost/C:\Documents%20and%20Settings\folder/previm\some\path\img.png)'
  call self.assert.equals(expected, previm#relative_to_absolute_imgpath(arg_line, arg_dir))
endfunction
"}}}
let s:t = vimtest#new('fetch_imgpath_elements') "{{{

function! s:t.nothing_when_empty()
  let arg = ''
  let expected = s:empty_img_elements()
  call self.assert.equals(expected, previm#fetch_imgpath_elements(arg))
endfunction

function! s:t.nothing_when_not_img_statement()
  let arg = '## hogeほげ'
  let expected = s:empty_img_elements()
  call self.assert.equals(expected, previm#fetch_imgpath_elements(arg))
endfunction

function! s:t.get_title_and_path()
  let arg = '![IMG](path/img.png)'
  let expected = {'title': 'IMG', 'path': 'path/img.png'}
  call self.assert.equals(expected, previm#fetch_imgpath_elements(arg))
endfunction

function! s:empty_img_elements()
  return {'title': '', 'path': ''}
endfunction
"}}}
