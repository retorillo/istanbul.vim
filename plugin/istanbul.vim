command! -nargs=0 IstanbulUpdate call s:IstanbulUpdate()
command! -nargs=0 IstanbulNext call s:IstanbulNext(0)
command! -nargs=0 IstanbulBack call s:IstanbulNext(1)
command! -nargs=0 IstanbulClear call s:IstanbulClear()
command! -nargs=* IstanbulMode call s:IstanbulMode(<f-args>)

function! s:parsejson(json)
  if !exists("*json_decode")
    return json_ponyfill#json_decode(a:json)
  endif
  return json_decode(a:json)
endfunction

function! s:uniq(array)
  let d = {}
  for i in a:array
    let d[i] = 1
  endfor
  return keys(d)
endfunction

let s:modes = {}
let s:uncoveredRanges = {}
let s:hasWindows = has('win64') + has('win32') + has('win16') + has('win95')
let s:pathSeparator = s:hasWindows ? '\\' : '/'

function! s:detectSeparator(path)
  let sep = matchstr(a:path, '/\|\\')
  return strlen(sep) > 0 ? sep : s:pathSeparator
endfunction

function! s:joinPath(...)
  let parts = []
  for part in a:000
    if len(parts) == 0
      let sep = s:detectSeparator(part)
    endif
    call add(parts, substitute(part, sep.'$', '', ''))
  endfor
  return join(parts, sep)
endfunction

function! s:getPathSimilarity(a, b)
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

function! s:findSimilarPath(pathes, path)
  let result = { 'path': '', 'similarity': 0 }
  for p in a:pathes
    let s = s:getPathSimilarity(p, a:path)
    if result.similarity < s
      let result.similarity = s
      let result.path = p
    endif
  endfor
  return result
endfunction

function! s:signCoverage(line, c, bufnr, type)
  let c = min([a:c, 99])
  if len(a:type) == 0
    if c > 0
      let name = 'covered'.c
      let text = c < 9 ? '0'.c : c
      exec 'sign define '.name.' text='.text.' texthl=covered'
    else
      let name = 'uncovered'
    endif
  else
    let t = toupper(s:makeSignText(a:type))
    let name = c > 0 ? 'covered'.t : 'uncovered'.t
    exec 'sign define '.name.' text='.t.' texthl='
      \ .(c > 0 ? 'covered' : 'uncovered')
  endif
  exec 'sign place '.a:line.' line='.a:line
    \ .' name='.name.' buffer='.a:bufnr
  return a:line
endfunction

function! s:makeRanges(arr)
  let ranges = []
  let start = -1
  for i in a:arr
    if start == -1
      let start = i
      let end = start
    elseif end + 1 == i
      let end = i
    else
      call add(ranges, [start, end])
      let start = i
      let end = start
    endif
  endfor
  if (start != -1)
    call add(ranges, [start, end])
  endif
  return ranges
endfunction

function! s:swapIndex(arr, i1, i2)
  if a:i1 != a:i2
    let v2 = a:arr[a:i2]
    let a:arr[a:i2] = a:arr[a:i1]
    let a:arr[a:i1] = v2
  endif
endfunction

function! s:sortNumbers(arr)
  let len = len(a:arr)
  let i1 = 0
  while i1 < len
    let min = a:arr[i1]
    let i2 = i1
    let i3 = i1
    while i2 < len
      if a:arr[i2] < min
        let min = a:arr[i2] < min ? a:arr[i2] : min
        let i3 = i2
      endif
      let i2 += 1
    endwhile
    call s:swapIndex(a:arr, i1, i3)
    let i1 += 1
  endwhile
  return a:arr
endfunction

function! s:makeSignText(chain)
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
  return abbreb
endfunction

function! s:IstanbulMode(...)
  let bufnr = bufnr('%')
  let m = get(s:modes, bufnr)
  if len(a:000) == 0
    let s:modes[bufnr] = (m + 1) % 2
  else
    if tolower(a:1) == 'line'
      let s:modes[bufnr] = 0
    elseif tolower(a:1) == 'branch'
      let s:modes[bufnr] = 1
    else
      echoerr 'Unkown mode: '.a:1
      return
    endif
  endif
  call s:IstanbulUpdate()
endfunction

function! s:IstanbulUpdate()
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

  let bufnr = bufnr('%')
  let bufpath = expand('%:p')

  let jsonPath = ''
  let filenames = ['coverage.json', 'coverage-final.json']
  let expandDir = '%:p:h'
  let dir = expand(expandDir)
  while len(dir) > 1 && !filereadable(jsonPath)
    for f in filenames
      let jsonPath = s:joinPath(dir, 'coverage', f)
      if filereadable(jsonPath)
        break
      end
    endfor
    let expandDir .= ':h'
    let dir = expand(expandDir)
  endwhile

  if !filereadable(jsonPath)
    echoerr '"'.jsonPath.'" is not found'
    return
  endif

  try
    let mode = get(s:modes, bufnr)
    let json = s:parsejson(join(readfile(jsonPath)))
    let similarPath = s:findSimilarPath(keys(json), bufpath)
    if similarPath.similarity == 0
      throw '"'.bufpath.'" does not found in "'.jsonPath.'"'
    endif
    let root = get(json, similarPath.path)
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
        let id = s:signCoverage(start, c, bufnr, '')
        if c <= 0
          call add(uncovered, id)
        endif
      endfor
      for key in keys(fnMap)
        let item = get(fnMap, key)
        let c = str2nr(get(f, key))
        let line = get(item, 'line')
        let id = s:signCoverage(line, c, bufnr, '')
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
        let id = s:signCoverage(line, min_c, bufnr, type)
        if min_c <= 0
          call add(uncovered, id)
        endif
      endfor
    endif
    call s:uniq(s:sortNumbers(uncovered))
    echohl Statement
    echo msg
    echohl None
    let range = s:makeRanges(uncovered)
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

function! s:IstanbulNext(reverse)
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
  exec "sign jump ".get(range, 0)." buffer=".bufnr
endfunction

function! s:IstanbulClear()
  let bufnr = bufnr('%')
  call remove(s:uncoveredRanges, bufnr)
  exec 'sign unplace * buffer='.bufnr
endfunction
