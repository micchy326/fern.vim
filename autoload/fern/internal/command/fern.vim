let s:Promise = vital#fern#import('Async.Promise')
let s:drawer_opener = 'topleft vsplit'

function! fern#internal#command#fern#command(mods, fargs) abort
  try
    let stay = fern#internal#args#pop(a:fargs, 'stay', v:false)
    let wait = fern#internal#args#pop(a:fargs, 'wait', v:false)
    let reveal = fern#internal#args#pop(a:fargs, 'reveal', '')
    let drawer = fern#internal#args#pop(a:fargs, 'drawer', v:false)
    if drawer
      let opener = s:drawer_opener
      let width = fern#internal#args#pop(a:fargs, 'width', '')
      let keep = fern#internal#args#pop(a:fargs, 'keep', v:false)
      let toggle = fern#internal#args#pop(a:fargs, 'toggle', v:false)
    else
      let opener = fern#internal#args#pop(a:fargs, 'opener', g:fern#opener)
      let width = ''
      let keep = v:false
      let toggle = v:false
    endif

    if len(a:fargs) isnot# 1
          \ || type(stay) isnot# v:t_bool
          \ || type(wait) isnot# v:t_bool
          \ || type(reveal) isnot# v:t_string
          \ || type(drawer) isnot# v:t_bool
          \ || type(opener) isnot# v:t_string
          \ || type(width) isnot# v:t_string
          \ || type(keep) isnot# v:t_bool
          \ || type(toggle) isnot# v:t_bool
      if empty(drawer)
        throw 'Usage: Fern {url} [-opener={opener}] [-stay] [-wait] [-reveal={reveal}]'
      else
        throw 'Usage: Fern {url} -drawer [-toggle] [-keep] [-width={width}] [-stay] [-wait] [-reveal={reveal}]'
      endif
    endif

    " Does all options are handled?
    call fern#internal#args#throw_if_dirty(a:fargs)

    " Force project drawer style when
    " - The current buffer is project drawer style fern
    " - The 'opener' is 'edit'
    if opener ==# 'edit' && fern#internal#drawer#is_drawer()
      let drawer = v:true
      let opener = s:drawer_opener
    endif

    let expr = expand(a:fargs[0])
    let path = fern#fri#format(
          \ expr =~# '^[^:]\+://'
          \   ? fern#fri#parse(expr)
          \   : fern#fri#from#filepath(fnamemodify(expand(expr), ':p'))
          \)
    " Build FRI for fern buffer from argument
    let fri = fern#fri#new({
          \ 'scheme': 'fern',
          \ 'path': path,
          \})
    let fri.authority = drawer
          \ ? printf('drawer:%d', tabpagenr())
          \ : ''
    let fri.query = extend(fri.query, {
          \ 'width': width,
          \ 'keep': keep,
          \})
    call fern#logger#debug('expr:', expr)
    call fern#logger#debug('fri:', fri)

    " A promise which will be resolved once the viewer become ready
    let waiter = fern#hook#promise('viewer:ready')

    " Register callback to reveal node
    let reveal = s:normalize_reveal(fri, reveal)
    if reveal !=# ''
      let waiter = waiter.then({ h -> fern#internal#viewer#reveal(h, reveal) })
    endif

    let winid_saved = win_getid()
    if fri.authority =~# '\<drawer\>'
      call fern#internal#drawer#open(fri, {
            \ 'mods': a:mods,
            \ 'toggle': toggle,
            \ 'opener': opener,
            \ 'stay': stay ? win_getid() : 0,
            \})
    else
      call fern#internal#viewer#open(fri, {
            \ 'mods': a:mods,
            \ 'opener': opener,
            \ 'stay': stay ? win_getid() : 0,
            \})
    endif

    if stay
      call win_gotoid(winid_saved)
    endif

    if wait
      let [_, err] = s:Promise.wait(waiter, {
            \ 'interval': 100,
            \ 'timeout': 5000,
            \})
      if err isnot# v:null
        throw printf('[fern] Failed to wait: %s', err)
      endif
    endif
  catch
    echohl ErrorMsg
    echomsg v:exception
    echohl None
    call fern#logger#debug(v:exception)
    call fern#logger#debug(v:throwpoint)
  endtry
endfunction

function! fern#internal#command#fern#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^-opener='
    return fern#internal#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^-reveal='
    return fern#internal#complete#reveal(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^-'
    return fern#internal#complete#options(a:arglead, a:cmdline, a:cursorpos)
  endif
  return fern#internal#complete#url(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:normalize_reveal(fri, reveal) abort
  let reveal = expand(a:reveal)
  if !fern#internal#filepath#is_absolute(reveal)
    return reveal
  endif
  " reveal points a real filesystem
  let fri = fern#fri#parse(a:fri.path)
  let root = '/' . fri.path
  let reveal = fern#internal#filepath#to_slash(reveal)
  let reveal = fern#internal#path#relative(reveal, root)
  return reveal
endfunction
