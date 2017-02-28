let s:keepcpo = &cpo
set cpo&vim

let s:windows = has('win64') || has('win32') ||  has('win16') || has('win95')
let s:sep = s:windows ? '\' : '/'

function! istanbul#path#ancestors(path)
  let ancestors = []
  let parts = split(a:path, '[\\/]', 1)
  let sep = istanbul#path#sep(a:path)
  let c = len(parts)
  while c > 0
    let c -= 1
    if empty(parts[c])
      continue
    endif
    call add(ancestors, join(parts[: c], sep))
  endwhile
  return ancestors
endfunction

function! istanbul#path#sep(path)
  let sep = matchstr(a:path, '[\\/]')
  return strlen(sep) > 0 ? sep : s:sep
endfunction

function! istanbul#path#join(...)
  let parts = []
  for part in a:000
    if len(parts) == 0
      let sep = istanbul#path#sep(part)
    endif
    call add(parts, substitute(substitute(part, '[\\/]', sep, 'g'), '[\\/]$', '', ''))
  endfor
  return join(parts, sep)
endfunction

function! istanbul#path#similarity(a, b)
  let lM = reverse(split(a:a, '[\\/]'))
  let lm = reverse(split(a:b, '[\\/]'))
  if (len(lM) < len(lm))
    let lx = lM
    let lM = lm
    let lm = lx
  endif
  let s = 0
  while s < len(lm) && tolower(lM[s]) == tolower(lm[s])
    let s += 1
  endwhile
  return s
endfunction

function! istanbul#path#sort(list)
  return sort(sort(a:list), 'istanbul#path#compare')
endfunction

function! istanbul#path#compare(l, r)
  return strlen(a:l) - strlen(a:r)
endfunction

function! istanbul#path#mostsimilar(pathes, path)
  let list = []
  let max = 0
  for p in a:pathes
    let s = istanbul#path#similarity(p, a:path)
    call add(list, [s, p])
    if max < s
      let max = s
    endif
  endfor
  return max > 0 ? istanbul#path#sort(
    \ map(
      \ filter(list, printf('v:val[0] >= %d', max)),
      \ 'v:val[1]'
    \ ))[0] : ''
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
