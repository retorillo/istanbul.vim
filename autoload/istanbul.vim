let s:keepcpo = &cpo
set cpo&vim

let s:modes = {}
let s:uncoveredRanges = {}

if !exists('g:istanbul#jsonPath')
  let g:istanbul#jsonPath = ['coverage/coverage.json', 'coverage/coverage-final.json']
endif

function! istanbul#parsejson(json)
  if !exists("*json_decode")
    return json_ponyfill#json_decode(a:json)
  endif
  return json_decode(a:json)
endfunction

function! istanbul#modecompl(lead, cmd, cursor)
  return ['line', 'branch']
endfunction

function! istanbul#mode(mode)
  let bufnr = bufnr('%')
  let m = get(s:modes, bufnr)
  if empty(a:mode)
    let s:modes[bufnr] = (m + 1) % 2
  else
    if tolower(a:mode) == 'line'
      let s:modes[bufnr] = 0
    elseif tolower(a:mode) == 'branch'
      let s:modes[bufnr] = 1
    else
      echoerr printf('Unkown mode: %s', a:mode)
      return
    endif
  endif
  call s:IstanbulUpdate('')
endfunction

function! istanbul#update(jsonPath)
  let bufnr = bufnr('%')
  let bufPath = expand('%:p')

  let jsonPath = a:jsonPath
  let expandDir = '%:p:h'
  let nextdir = expand(expandDir)
  let dir = ''
  while dir != nextdir && empty(jsonPath)
    let dir = nextdir
    for file in g:istanbul#jsonPath
      let path = istanbul#path#join(dir, file)
      if filereadable(path)
        let jsonPath = path
        break
      end
    endfor
    let expandDir .= ':h'
    let nextdir = expand(expandDir)
  endwhile
  if empty(jsonPath)
    echoerr printf('coverage.json is not found. (g:istanbul#jsonPath = %s)',
      \ string(g:istanbul#jsonPath))
    return
  endif
  try
    let mode = get(s:modes, bufnr)
    let json = istanbul#parsejson(join(readfile(jsonPath)))
    let similarPath = istanbul#path#mostsimilar(keys(json), bufPath)
    if empty(similarPath)
      throw printf('"%s" does not found in "%s"', bufPath, jsonPath)
    endif
    let root = get(json, similarPath)
    let uncovered = []
    exec printf('sign unplace * buffer=%s', bufnr)
    if mode == 0
      let msg = 'LINE COVERAGE'
      let statementMap = get(root, 'statementMap')
      let s = get(root, 's')
      let fnMap = get(root, 'fnMap')
      let f = get(root, 'f')
      for key in keys(statementMap)
        let item = get(statementMap, key)
        let c = str2nr(get(s, key))
        let start = get(get(item, 'start'), 'line')
        let id = istanbul#sign#place(start, c, bufnr, '')
        if c <= 0
          call add(uncovered, id)
        endif
      endfor
      for key in keys(fnMap)
        let item = get(fnMap, key)
        let c = str2nr(get(f, key))
        let line = get(item, 'line')
        let id = istanbul#sign#place(line, c, bufnr, '')
        if c <= 0
          call add(uncovered, id)
        endif
      endfor
    else
      let msg = 'BRANCH COVERAGE'
      let branchMap = get(root, 'branchMap')
      let b = get(root, 'b')
      for key in keys(branchMap)
        let item = get(branchMap, key)
        let c = get(b, key)
        let line = get(item, 'line')
        let type = get(item, 'type')
        let min_c = type(c) == 3 ? min(c) : c
        let id = istanbul#sign#place(line, min_c, bufnr, type)
        if min_c <= 0
          call add(uncovered, id)
        endif
      endfor
    endif
    call istanbul#numlist#uniq(istanbul#numlist#sort(uncovered))
    echohl Statement
    echo msg
    echohl None
    let range = istanbul#numlist#mkrange(uncovered)
    let s:uncoveredRanges[bufnr] = range

    let qflist = filter(getqflist(),
      \ printf('v:val["text"] !~ "^ISTANBUL\\.VIM:" || v:val["bufnr"] != %d', bufnr))
    for r in range
      if r[0] == r[1]
        let qfmsg = printf('ISTANBUL.VIM: Uncovered line %d', r[0])
      else
        let qfmsg = printf('ISTANBUL.VIM: Uncovered range from line %d to %d', r[0], r[1])
      endif
      call add(qflist, {
        \ 'bufnr': bufnr,
        \ 'lnum': r[0],
        \ 'text': qfmsg,
        \ 'type': 'W',
        \ })
    endfor
    call setqflist(qflist)
  catch
    echoerr v:exception
  endtry
endfunction

function! istanbul#next(reverse)
  let bufnr = bufnr('%')
  if !has_key(s:uncoveredRanges, bufnr)
    echoerr 'No instanbul information loaded on current buffer'
    return
  endif
  let rangeList = get(s:uncoveredRanges, bufnr)
  if len(rangeList) == 0
    echoerr 'There are no uncovered lines on current buffer'
    return
  endif
  let cur = line('.')
  for r in a:reverse ? reverse(copy(rangeList)) : rangeList
    if (!a:reverse && cur < get(r, 0))
      \ || (a:reverse && cur > get(r, 0))
      let range = r
      break
    endif
  endfor
  if !exists('range')
    let range = get(rangeList, a:reverse ? len(rangeList) - 1 : 0)
  endif
  execute printf('sign jump %d buffer=%d', get(range, 0), bufnr)
endfunction

function! istanbul#clear()
  let bufnr = bufnr('%')
  call remove(s:uncoveredRanges, bufnr)
  exec printf('sign unplace * buffer=%d', bufnr)
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
