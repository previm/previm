let s:t = vimtest#new('valid filetype for using :PrevimOpen')

function! s:t.setup()
  let self._ft = &filetype
endfunction

function! s:t.teardown()
  let &filetype = self._ft
  call self._clean_command()
endfunction

function! s:t._clean_command()
  if exists(':PrevimOpen') == 2
    delcommand PrevimOpen
  endif
endfunction

" helper
function! s:t._assert_filetype(ft, expected)
  let &filetype = a:ft
  let actual = exists(':PrevimOpen')
  if actual ==# a:expected
    call self.assert.success()
  else
    call self.assert.fail(printf("'%s': expected %d but actual %d", a:ft, a:expected, actual))
  endif
endfunction
"""

function! s:t.invalid_filetype()
  call self._assert_filetype('', 0)
  call self._assert_filetype('rb', 0)
  call self._assert_filetype('php', 0)
endfunction

function! s:t.valid_filetype()
  for type in [
        \ 'markdown', 'mkd', 'rst', 'textile',
        \ 'aaa.markdown', 'mkd.foo', 'bb.rst.cc', 'a.b.c.textile',
        \]
    call self._assert_filetype(type, 2)
    call self._clean_command()
  endfor
endfunction

