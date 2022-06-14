let s:source_map = [
\  {
\    'name': 'asciidoctor/core',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/asciidoctor.min.js',
\        'url': 'https://cdn.jsdelivr.net/npm/@asciidoctor/core@latest/dist/browser/asciidoctor.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'highlight',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/highlight.pack.js',
\        'url': 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@latest/build/highlight.min.js',
\      },
\      {
\        'type': 'css',
\        'path': 'preview/_/css/lib/highlight.css',
\        'url': 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@latest/build/styles/default.min.css',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-abbr',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-abbr.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-abbr/master/dist/markdown-it-abbr.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-checkbox',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-checkbox.min.js',
\        'url': 'https://raw.githubusercontent.com/mcecot/markdown-it-checkbox/master/dist/markdown-it-checkbox.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-cjk-breaks',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-cjk-breaks.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-cjk-breaks/master/dist/markdown-it-cjk-breaks.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-deflist',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-deflist.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-deflist/master/dist/markdown-it-deflist.min.js'
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-footnote',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-footnote.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-footnote/master/dist/markdown-it-footnote.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-sub',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-sub.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-sub/master/dist/markdown-it-sub.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-sup',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-sup.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-sup/master/dist/markdown-it-sup.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it/master/dist/markdown-it.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'textile',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/textile.js',
\        'url': 'https://raw.githubusercontent.com/borgar/textile-js/master/lib/textile.js',
\      },
\    ],
\  },
\  {
\    'name': 'mermaid',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/mermaid.min.js',
\        'url': 'https://cdn.jsdelivr.net/npm/mermaid@latest/dist/mermaid.min.js',
\        'code': ['mermaid.init();']
\      },
\    ],
\  },
\] + get(g:, 'previm_extra_libraries', [])

let s:base_dir = expand('<sfile>:h:h:h')

function! previm#assets#update() abort
  for l:i in s:source_map
    echo 'Updating ' . l:i['name'] . '...'
    for l:file in l:i['files']
      echo '  ' . l:file['path']
      let l:url = l:file['url']
      let l:file = s:base_dir . '/' . l:file['path']
      let l:cmd = printf('curl --create-dirs -s -o %s %s', l:file, l:url)
      call system(l:cmd)
    endfor
  endfor
endfunction

function! previm#assets#js() abort
  let l:files = []
  for l:i in s:source_map
    for l:file in l:i['files']
      if l:file['type'] ==# 'js'
        call add(l:files, l:file['path'])
      endif
    endfor
  endfor
  return l:files
endfunction

function! previm#assets#css() abort
  let l:files = []
  for l:i in s:source_map
    for l:file in l:i['files']
      if l:file['type'] ==# 'css'
        call add(l:files, l:file['path'])
      endif
    endfor
  endfor
  return l:files
endfunction

function! previm#assets#code() abort
  let l:code = []
  for l:i in s:source_map
    for l:file in l:i['files']
      if has_key(l:file, 'code')
        let l:code += l:file['code']
      endif
    endfor
  endfor
  return l:code
endfunction
