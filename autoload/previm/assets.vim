let s:source_map = [
\  {
\    'name': 'asciidoctor/core',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/asciidoctor.min.js',
\        'url': 'https://cdn.jsdelivr.net/npm/@asciidoctor/core@latest/dist/browser/asciidoctor.min.js'
\      },
\    ],
\  },
\  {
\    'name': 'highlight',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/highlight.pack.js',
\        'url': 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.5.1/build/highlight.min.js'
\      },
\      {
\        'type': 'css',
\        'path': 'preview/_/css/lib/highlight.css',
\        'url': 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.5.1/build/styles/default.min.css'
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-checkbox',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it-checkbox.min.js',
\        'url': 'https://raw.githubusercontent.com/mcecot/markdown-it-checkbox/master/dist/markdown-it-checkbox.min.js'
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
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-footnote/master/dist/markdown-it-footnote.min.js'
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/markdown-it.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it/master/dist/markdown-it.min.js'
\      },
\    ],
\  },
\  {
\    'name': 'textile',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/textile.js',
\        'url': 'https://raw.githubusercontent.com/borgar/textile-js/master/lib/textile.js'
\      },
\    ],
\  },
\  {
\    'name': 'mermain',
\    'files': [
\      {
\        'type': 'js',
\        'path': 'preview/_/js/lib/mermaid.min.js',
\        'url': 'https://cdn.jsdelivr.net/npm/mermaid@latest/dist/mermaid.min.js'
\      },
\    ],
\  },
\]

let s:base_dir = expand('<sfile>:h:h:h')

function! previm#assets#update() abort
  for l:i in s:source_map
    echo 'Updating ' .. l:i['name'] .. '...'
    for l:file in l:i['files']
      echo '  ' .. l:file['path']
      let l:url = l:file['url']
      let l:file = s:base_dir .. '/' .. l:file['path']
      let l:cmd = printf('curl -s -o %s %s', l:file, l:url)
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
