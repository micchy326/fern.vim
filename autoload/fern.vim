let s:root = expand('<sfile>:p:h')
let s:Config = vital#fern#import('Config')

" Define Public constant
let g:fern#STATUS_NONE = 0
let g:fern#STATUS_COLLAPSED = 1
let g:fern#STATUS_EXPANDED = 2
lockvar g:fern#STATUS_NONE
lockvar g:fern#STATUS_COLLAPSED
lockvar g:fern#STATUS_EXPANDED

let g:fern#DEBUG = 0
let g:fern#INFO = 1
let g:fern#WARN = 2
let g:fern#ERROR = 3
lockvar g:fern#DEBUG
lockvar g:fern#INFO
lockvar g:fern#WARN
lockvar g:fern#ERROR

" Define Public variables
call s:Config.config(expand('<sfile>:p'), {
      \ 'profile': 0,
      \ 'logfile': v:null,
      \ 'loglevel': g:fern#INFO,
      \ 'opener': 'edit',
      \ 'keepalt_on_edit': 0,
      \ 'keepjumps_on_edit': 0,
      \ 'disable_default_mappings': 0,
      \ 'disable_viewer_auto_duplication': 0,
      \ 'disable_drawer_auto_winfixwidth': 0,
      \ 'disable_drawer_auto_resize': 0,
      \ 'disable_drawer_auto_quit': 0,
      \ 'default_hidden': 0,
      \ 'default_include': '',
      \ 'default_exclude': '',
      \ 'renderer': 'default',
      \ 'renderers': {},
      \ 'comparator': 'default',
      \ 'comparators': {},
      \ 'drawer_width': 30,
      \ 'drawer_keep': v:false,
      \ 'mark_symbol': '*',
      \})

function! fern#version() abort
  if !executable('git')
    echohl ErrorMsg
    echo '[fern] "git" is not executable'
    echohl None
    return
  endif
  let r = system(printf('git -C %s describe --tags --always --dirty', s:root))
  echo printf('[fern] %s', r)
endfunction
