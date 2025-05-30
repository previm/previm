if !exists('g:previm_disable_default_ft_detect')
  au BufRead,BufNewFile *.pu,*.uml,*.plantuml,*.puml setfiletype plantuml
endif 