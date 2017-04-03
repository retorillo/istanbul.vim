let s:keepcpo = &cpo
set cpo&vim

let s:modes = {}

if !exists('g:istanbul#jsonPath')
  let g:istanbul#jsonPath = ['coverage/coverage.json', 'coverage/coverage-final.json']
endif
if !exists('g:istanbul#jumpStrategy')
  let g:istanbul#jumpStrategy = 'cyclic'
endif

function! istanbul#parsejson(json)
  if !exists("*json_decode")
    return json_ponyfill#json_decode(a:json, { 'progress': 1 })
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
      throw istanbul#error#format('InvalidMode', a:mode)
    endif
  endif
  call istanbul#update('')
endfunction

function! istanbul#findjson(file)
  for dir in istanbul#path#ancestors(fnamemodify(a:file, ':p:h'))
    for f in g:istanbul#jsonPath
      let path = istanbul#path#join(dir, f)
      if filereadable(path)
        return path
      endif
    endfor
  endfor
  return ''
endfunction

function! istanbul#update(jsonPath)
  let bufnr = bufnr('%')
  let bufPath = expand('%:p')
  let jsonPath = empty(a:jsonPath) ? istanbul#findjson(bufPath) : a:jsonPath
  if empty(jsonPath)
    throw istanbul#error#format('JsonNotFound', string(g:istanbul#jsonPath))
  endif
  try
    let mode = get(s:modes, bufnr)
    let json = istanbul#parsejson(join(readfile(jsonPath)))
    let similarPath = istanbul#path#mostsimilar(keys(json), bufPath)
    if empty(similarPath)
      throw istanbul#error#format('EntryNotFound', expand('%:.'), jsonPath)
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
    let ranges = istanbul#numlist#mkrange(uncovered)
    call istanbul#quickfix#update(bufnr, ranges)
  catch
    echoerr v:exception
  endtry
endfunction

function! istanbul#jump(bang, count)
  let cyclic = g:istanbul#jumpStrategy == 'cyclic'
  let nr = istanbul#quickfix#jumpnr(cyclic, a:bang, bufnr('%'), line('.'),
    \ '^'.g:istanbul#quickfix#prefix, a:count)
  if nr > 0
    execute printf('cc%s %d', a:bang ? '!' : '', nr)
    normal zO
    normal z.
  elseif nr == g:istanbul#quickfix#errjumpdesc
    throw istanbul#error#format('OutOfQuickfixDesc', g:istanbul#jumpStrategy)
  elseif nr == g:istanbul#quickfix#errjumpasc
    throw istanbul#error#format('OutOfQuickfixAsc', g:istanbul#jumpStrategy)
  elseif nr == g:istanbul#quickfix#errjumpempty
    throw istanbul#error#format('EmptyQuickfix')
  endif
endfunction

function! istanbul#clear(bang)
  let bufnr = bufnr('%')
  exec printf('sign unplace * buffer=%d', bufnr)
  call istanbul#quickfix#clear(a:bang ? -1 : bufnr)
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
