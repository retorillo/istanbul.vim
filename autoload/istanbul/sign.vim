let s:keepcpo = &cpo
set cpo&vim

let s:init = 0

function! istanbul#sign#init()
  if s:init
    return
  endif
  if !has('gui_running') && &t_Co < 256
    hi uncovered_nt guifg=red guibg=red ctermfg=red ctermbg=red
    hi uncovered guifg=white guibg=red ctermfg=white ctermbg=red
    hi covered guifg=white guibg=blue ctermfg=white ctermbg=blue
  else
    hi uncovered_nt guifg=#d70000 guibg=#d70000 ctermfg=160 ctermbg=160
    hi uncovered guifg=#ffd700 guibg=#d70000 ctermfg=225 ctermbg=160
    hi covered guifg=#00d7ff guibg=#005faf ctermfg=45 ctermbg=25
  endif
  sign define uncovered text=00 texthl=uncovered_nt
  let s:init = 1
endfunction

function! istanbul#sign#place(line, c, bufnr, type)
  call istanbul#sign#init()
  let c = min([a:c, 99])
  if len(a:type) == 0
    if c > 0
      let name = 'covered'.c
      let text = c < 9 ? '0'.c : c
      execute printf('sign define %s text=%s texthl=covered',
        \ name, text)
    else
      let name = 'uncovered'
    endif
  else
    let t = istanbul#sign#format(a:type)
    let name = c > 0 ? 'covered'.t : 'uncovered'.t
    execute printf('sign define %s text=%s texthl=%s',
      \ name, t , c > 0 ? 'covered' : 'uncovered')
  endif
  if a:line > 0
    execute printf('sign place %d line=%d name=%s buffer=%d',
      \ a:line, a:line, name, a:bufnr)
  endif
  return a:line
endfunction

function! istanbul#sign#format(chain)
  if len(a:chain) <= 2
    return a:chain
  endif
  let words = split(a:chain, '-')
  if len(words) == 1
    return a:chain[0:1]
  endif
  let abbreb = ''
  for i in words
    let abbreb = abbreb.i[0:0]
  endfor
  return toupper(abbreb)
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
