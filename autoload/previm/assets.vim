let s:source_map = [
\  {
\    'name': 'asciidoctor/core',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/asciidoctor.min.js',
\        'url': 'https://cdn.jsdelivr.net/npm/@asciidoctor/core@latest/dist/browser/asciidoctor.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'highlight',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/highlight.pack.js',
\        'url': 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@latest/build/highlight.min.js',
\      },
\      {
\        'type': 'css',
\        'path': '_/css/lib/highlight.css',
\        'url': 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@latest/build/styles/default.min.css',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-abbr',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it-abbr.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-abbr/master/dist/markdown-it-abbr.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-checkbox',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it-checkbox.min.js',
\        'url': 'https://raw.githubusercontent.com/mcecot/markdown-it-checkbox/master/dist/markdown-it-checkbox.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-cjk-breaks',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it-cjk-breaks.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-cjk-breaks/master/dist/markdown-it-cjk-breaks.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-deflist',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it-deflist.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-deflist/master/dist/markdown-it-deflist.min.js'
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-footnote',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it-footnote.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-footnote/master/dist/markdown-it-footnote.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-sub',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it-sub.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-sub/master/dist/markdown-it-sub.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it-sup',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it-sup.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it-sup/master/dist/markdown-it-sup.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'markdown-it',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/markdown-it.min.js',
\        'url': 'https://raw.githubusercontent.com/markdown-it/markdown-it/master/dist/markdown-it.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'textile',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/textile.min.js',
\        'url': 'https://cdn.jsdelivr.net/npm/textile-js@latest/lib/textile.min.js',
\      },
\    ],
\  },
\  {
\    'name': 'mermaid',
\    'files': [
\      {
\        'type': 'js',
\        'path': '_/js/lib/mermaid.min.js',
\        'url': 'https://cdn.jsdelivr.net/npm/mermaid@latest/dist/mermaid.min.js',
\        'code': [
\          'mermaid.init();',
\          'Array.prototype.forEach.call(',
\          '  _doc.querySelectorAll(''.mermaid > svg'')',
\          ', (mermaidImage) => mermaidImage.removeAttribute(''height'')',
\          ');',
\        ]
\      },
\    ],
\  },
\]

let s:base_dir = expand('<sfile>:h:h:h') . '/preview'

function! previm#assets#update() abort
  let oldmore = &more
  set nomore
  for l:i in s:source_map
    echo 'Updating ' . l:i['name'] . '...'
    for l:file in l:i['files']
      if !has_key(l:file, 'path') || !has_key(l:file, 'url')
        continue
      endif
      echo '  ' . l:file['path']
      let l:url = l:file['url']
      let l:file = s:base_dir . '/' . l:file['path']
      let l:cmd = printf('curl --create-dirs -s -o %s %s', l:file, l:url)
      call system(l:cmd)
    endfor
  endfor
  for l:i in filter(copy(get(g:, 'previm_extra_libraries', [])), {k, v -> !has_key(v, 'enabled') || v['enabled']})
    echo 'Updating ' . l:i['name'] . '...'
    for l:file in l:i['files']
      if !has_key(l:file, 'path') || !has_key(l:file, 'url')
        continue
      endif
      echo '  ' . l:file['path']
      let l:url = l:file['url']
      let l:file = previm#preview_base_dir() . '/' . l:file['path']
      let l:cmd = printf('curl --create-dirs -s -o %s %s', l:file, l:url)
      call system(l:cmd)
    endfor
  endfor
  redraw
  let &more = oldmore
endfunction

function! previm#assets#js() abort
  let l:files = []
  for l:i in s:source_map
    for l:file in l:i['files']
      if l:file['type'] ==# 'js' && has_key(l:file, 'path')
        call add(l:files, l:file['path'])
      endif
    endfor
  endfor
  for l:i in filter(copy(get(g:, 'previm_extra_libraries', [])), {k, v -> !has_key(v, 'enabled') || v['enabled']})
    for l:file in l:i['files']
      if l:file['type'] ==# 'js' && has_key(l:file, 'path')
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
      if l:file['type'] ==# 'css' && has_key(l:file, 'path')
        call add(l:files, l:file['path'])
      endif
    endfor
  endfor
  for l:i in filter(copy(get(g:, 'previm_extra_libraries', [])), {k, v -> !has_key(v, 'enabled') || v['enabled']})
    for l:file in l:i['files']
      if l:file['type'] ==# 'css' && has_key(l:file, 'path')
        call add(l:files, l:file['path'])
      endif
    endfor
  endfor
  return l:files
endfunction

function! previm#assets#init() abort
  let l:init = []
  for l:i in s:source_map
    for l:file in l:i['files']
      if has_key(l:file, 'init')
        let l:init += l:file['init']
      endif
    endfor
  endfor
  for l:i in filter(copy(get(g:, 'previm_extra_libraries', [])), {k, v -> !has_key(v, 'enabled') || v['enabled']})
    for l:file in l:i['files']
      if has_key(l:file, 'init')
        let l:init += l:file['init']
      endif
    endfor
  endfor
  return l:init
endfunction

function! previm#assets#style() abort
  let l:style = []
  for l:i in s:source_map
    for l:file in l:i['files']
      if l:file['type'] ==# 'css' && has_key(l:file, 'style')
        let l:style += l:file['style']
      endif
    endfor
  endfor
  for l:i in filter(copy(get(g:, 'previm_extra_libraries', [])), {k, v -> !has_key(v, 'enabled') || v['enabled']})
    for l:file in l:i['files']
      if l:file['type'] ==# 'css' && has_key(l:file, 'style')
        let l:style += l:file['style']
      endif
    endfor
  endfor
  return l:style
endfunction

function! previm#assets#code() abort
  let l:code = []
  for l:i in s:source_map
    for l:file in l:i['files']
      if l:file['type'] ==# 'js' && has_key(l:file, 'code')
        let l:code += l:file['code']
      endif
    endfor
  endfor
  for l:i in filter(copy(get(g:, 'previm_extra_libraries', [])), {k, v -> !has_key(v, 'enabled') || v['enabled']})
    for l:file in l:i['files']
      if l:file['type'] ==# 'js' && has_key(l:file, 'code')
        let l:code += l:file['code']
      endif
    endfor
  endfor
  return l:code
endfunction
