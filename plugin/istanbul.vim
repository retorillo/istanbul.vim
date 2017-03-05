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
  \ -count=1
  \ -bang
  \ -nargs=?
  \ IstanbulNext
  \ call istanbul#jump(!empty('<bang>'), <count>)
command! 
  \ -count=1
  \ -bang
  \ -nargs=?
  \ IstanbulBack
  \ call istanbul#jump(!empty('<bang>'), -<count>)
command!
  \ -bang
  \ -nargs=0
  \ IstanbulClear
  \ call istanbul#clear(!empty('<bang>'))
command!
  \ -nargs=? 
  \ -complete=file
  \ IstanbulUpdate
  \ call istanbul#update(expand('<args>'))

let &cpo = s:keepcpo
unlet s:keepcpo
