let s:keepcpo = &cpo
set cpo&vim

if !exists('g:istanbul#quickfix#prefix')
  let g:istanbul#quickfix#prefix = 'ISTANBUL:'
endif

let g:istanbul#quickfix#errjumpdesc = -1
let g:istanbul#quickfix#errjumpasc = -2
let g:istanbul#quickfix#errjumpempty = -3

function! istanbul#quickfix#format(range)
  if a:range[0] == a:range[1]
    return printf('%s Uncovered line %d',
      \ g:istanbul#quickfix#prefix,
      \ a:range[0])
  else
    return printf('%s Uncovered range from line %d to %d',
      \ g:istanbul#quickfix#prefix,
      \ a:range[0], a:range[1])
  endif
endfunction
function! istanbul#quickfix#update(bufnr, ranges)
  if g:istanbul#quickfix#prefix !~ '\v^[-a-zA-Z0-9:_]+$'
    throw g:istanbul#error#format("InvalidPrefix", g:istanbul#quickfix#prefix)
  endif
  let qflist = filter(getqflist(),
    \ printf('v:val.text !~ "^%s" || v:val.bufnr != %d', g:istanbul#quickfix#prefix, a:bufnr))
  for r in a:ranges
    call add(qflist, {
      \ 'bufnr': a:bufnr,
      \ 'lnum': r[0],
      \ 'text': istanbul#quickfix#format(r),
      \ })
  endfor
  call setqflist(qflist)
endfunction
function! istanbul#quickfix#jumpnr(cyclic, switchbuf, curbufnr, curline, pattern, offset)
  let reverse = a:offset < 0
  let filtered = []
  let nr = 0
  for entry in getqflist()
    let nr += 1
    let bufnr = get(entry, 'bufnr', -1)
    if !a:switchbuf && bufnr != a:curbufnr
      continue
    endif
    let line = get(entry, 'lnum', 0)
    if line == 0
      continue
    endif
    if get(entry, 'text', '') !~ a:pattern
      continue
    endif
    call add(filtered, { 'nr': nr, 'line': line, 'bufnr': bufnr })
  endfor
  let len = len(filtered)
  if len == 0
    return g:istanbul#quickfix#errjumpempty
  endif
  let buffound = 0
  let curindex = reverse ? len : -1
  for item in reverse ? reverse(copy(filtered)) : filtered
    if item.bufnr == a:curbufnr
      let buffound += 1
      if reverse ? item.line < a:curline : item.line > a:curline
        break
      endif
    elseif buffound > 0
      break
    endif
    let curindex += reverse ? -1 : 1
  endfor
  let curindex += a:offset
  if a:cyclic
    let curindex = curindex % len
    if curindex < 0
      let curindex += len
    endif
    return filtered[curindex].nr
  else
    if curindex < 0
      return g:istanbul#quickfix#errjumpdesc
    elseif curindex > len - 1
      return g:istanbul#quickfix#errjumpasc
    else
      return filtered[curindex].nr
    endif
  endif
endfunction
function! istanbul#quickfix#clear(bufnr)
  let filtered = []
  for q in getqflist()
    let bufnr = get(q, 'bufnr', 0)
    let text = get(q, 'text', '')
    if bufnr != a:bufnr || text !~ '^'.g:istanbul#quickfix#prefix
      call add(filtered, q)
    endif
  endfor
  call setqflist(filtered)
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
