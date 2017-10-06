let s:keepcpo = &cpo
set cpo&vim

let s:bufferstate = {}
let s:jsoncache = {}

if !exists('g:istanbul#jsonPath')
  let g:istanbul#jsonPath = ['coverage/coverage.json', 'coverage/coverage-final.json']
endif
if !exists('g:istanbul#jumpStrategy')
  let g:istanbul#jumpStrategy = 'cyclic'
endif
if !exists('g:istanbul#store')
  let g:istanbul#store = 'quickfix'
endif

function! istanbul#parsejson(path)
  try
    let ftime = getftime(a:path)
    if has_key(s:jsoncache, a:path) && s:jsoncache[a:path]['ftime'] == ftime
      return s:jsoncache[a:path]['json']
    endif
    let read = join(readfile(a:path))
    if !exists("*json_decode")
      let json = json_ponyfill#json_decode(read, { 'python': 1, 'progress': 1 })
    else
      let json = json_decode(read)
    endif
    let s:jsoncache[a:path] = { 'ftime': ftime, 'json': json  }
    return json
  catch
    echoerr v:exception
  endtry
endfunction

function! istanbul#modecompl(lead, cmd, cursor)
  return ['line', 'branch']
endfunction

function! istanbul#mode(mode)
  let bufnr = bufnr('%')
  let state = get(s:bufferstate, bufnr)
  if !empty(state)
    let cur = state['mode']
    if empty(a:mode)
      let state['mode'] = (cur + 1) % 2
    else
      if tolower(a:mode) == 'line'
        let state['mode'] = 0
      elseif tolower(a:mode) == 'branch'
        let state['mode'] = 1
      else
        throw istanbul#error#format('InvalidMode', a:mode)
      endif
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

function! istanbul#toggle()
  let bufnr = bufnr('%')
  if has_key(s:bufferstate, bufnr)
    let state = s:bufferstate[bufnr]
    let state['visible'] = !state['visible']
    if !state['visible']
      call istanbul#clear(0)
    else
      call istanbul#update('')
    endif
  else
    call istanbul#update('')
  endif
endfunction

function! istanbul#update(jsonpath)
  let bufnr = bufnr('%')
  let bufpath = expand('%:p')
  if empty(a:jsonpath) && has_key(s:bufferstate, bufnr)
    let state = s:bufferstate[bufnr]
  else
    let state = {
      \ 'mode': 0,
      \ 'jsonpath': !empty(a:jsonpath) ? a:jsonpath : istanbul#findjson(bufpath),
      \ 'visible': 1,
      \ }
  endif
  if empty(state['jsonpath'])
    throw istanbul#error#format('JsonNotFound', string(g:istanbul#jsonPath))
  endif
  try
    let json = istanbul#parsejson(state['jsonpath'])
    let similarpath = istanbul#path#mostsimilar(keys(json), bufpath)
    if empty(similarpath)
      throw istanbul#error#format('EntryNotFound', expand('%:.'), state['jsonpath'])
    endif
    let root = get(json, similarpath)
    let uncovered = []
    exec printf('sign unplace * buffer=%s', bufnr)
    if state['mode'] == 0
      let modestr = [ 'line', 'lines' ]
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
      let modestr = [ 'branch', 'branches' ]
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
    let ranges = istanbul#numlist#mkrange(uncovered)
    call istanbul#quickfix#update(bufnr, ranges, modestr)
    echohl Statement
    if len(uncovered)
      let qfstore = g:istanbul#store =~ '^l' ? 'location-list' : 'quickfix'
      let qfprefix = g:istanbul#store =~ '^l' ? 'l' : 'c'
      echo printf('%d uncovered %s are stored to %s. Use :%snext, and :%sprev to explorer.',
        \ len(uncovered), len(uncovered) == 1 ? modestr[0] : modestr[1],
        \ qfstore, qfprefix, qfprefix)
    else
      echo printf('No uncovered %s.', modestr[1])
    endif
    echohl None
    let state['visible'] = 1
    let s:bufferstate[bufnr] = state
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
    try
      normal zO
    catch /^Vim(normal):E490:/
      " NOP
    endtry
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
