if exists('g:istanbul#version')
  finish
endif
let g:istanbul#version = '1.3.0'
let s:keepcpo = &cpo
set cpo&vim

command!
  \ -nargs=*
  \ -complete=customlist,istanbul#modecompl
  \ IstanbulMode
  \ call istanbul#mode('<args>')
command!
  \ -nargs=0
  \ IstanbulNext
  \ call istanbul#next(0)
command! 
  \ -nargs=0
  \ IstanbulBack
  \ call istanbul#next(1)
command!
  \ -nargs=0
  \ IstanbulClear
  \ call istanbul#clear()
command!
  \ -nargs=? 
  \ -complete=file
  \ IstanbulUpdate
  \ call istanbul#update(expand('<args>'))

let &cpo = s:keepcpo
unlet s:keepcpo
