command! -nargs=0 IstanbulUpdate call s:IstanbulUpdate()
command! -nargs=0 IstanbulNext call s:IstanbulNext(0)
command! -nargs=0 IstanbulBack call s:IstanbulNext(1)
command! -nargs=0 IstanbulClear call s:IstanbulClear()

if !exists('g:istanbul#disableKeymaps') || g:istanbul#disableKeymaps
  nmap <C-I><C-I> :IstanbulUpdate<CR>
  nmap <C-I><C-N> :IstanbulNext<CR>
  nmap <C-I><C-B> :IstanbulBack<CR>
  nmap <C-I><C-D> :IstanbulClear<CR>
endif

let s:uncoveredRangeList = {}
let s:hasWindows = has('win64') + has('win32') + has('win16') + has('win95')
let s:pathSeparator = s:hasWindows ? '\' : '/'

function! s:detectSeparator(path)
  let sep = matchstr(a:path, '/\|\\')
  return strlen(sep) > 0 ? sep : s:pathSeparator
endfunction

function! s:joinPath(a, b)
  let sep = s:detectSeparator(a:a)
  return substitute(a:a, sep.'$', '', '').sep.a:b
endfunction

function! s:isWindowsPath(path)
  return s:detectSeparator(a:path) != '/'
endfunction

function! s:msysToWindowsPath(path)
  return substitute(substitute(a:path, '^/\([a-z]\)/', '\1:/', ''), '/', '\', 'g')
endfunction

function! s:signCoverage(line, c, bufnr)
  let c = min([a:c, 99])
  exec 'sign place '.a:line.' line='.a:line
    \ .' name='.(c > 0 ? 'covered'.c : 'uncovered').' buffer='.a:bufnr
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

function! s:IstanbulUpdate()
  hi uncovered guifg=#d70000 guibg=#d70000 ctermfg=160 ctermbg=160
  hi covered guifg=#00d7ff guibg=#005faf ctermfg=45 ctermbg=25
  sign define uncovered text=00 texthl=uncovered
  let c = 1
  while c < 100
    let text = c < 9 ? '0'.c : c
    exec 'sign define covered'.c.' text='.text.' texthl=covered'
    let c += 1
  endwhile

  let bufnr = bufnr('%')
  let bufpath = expand('%:p')
  let bufdir = expand('%:h')
  let jsonPath = s:joinPath(bufdir, 'coverage'.s:pathSeparator.'coverage.json')
  if !filereadable(jsonPath)
    echoerr '"'.jsonPath.'" is not found'
    return
  endif

  try
    let json = json_decode(join(readfile(jsonPath)))

    let root = 0
    for path in keys(json)
      if s:isWindowsPath(path)
        if tolower(path) == tolower(s:msysToWindowsPath(bufpath))
          let root = get(json, path)
          break
        endif
      else
        if s:hasWindows
          if tolower(path) == tolower(bufpath)
            let root = get(json, path)
            break
          endif
        else
          if path == bufpath
            let root = get(json, path)
            break
          endif
        endif
      endif
    endfor

    if type(root) == 0
      throw '"'.bufpath.'" does not found in "'.jsonPath.'"'
    endif

    let statementMap = get(root, 'statementMap')
    let s = get(root, 's')
    let fnMap = get(root, 'fnMap')
    let f = get(root, 'f')
    exec 'sign unplace *'
    let uncovered = []
    for key in keys(statementMap)
      let item = get(statementMap, key)
      let c = str2nr(get(s, key))
      let start = get(get(item, 'start'), 'line')
      let id = s:signCoverage(start, c, bufnr)
      if c <= 0
        call add(uncovered, id)
      endif
    endfor
    for key in keys(fnMap)
      let item = get(fnMap, key)
      let c = str2nr(get(f, key))
      let line = get(item, 'line')
      let id = s:signCoverage(line, c, bufnr)
      if c <= 0
        call add(uncovered, id)
      endif
    endfor
    call uniq(s:sortNumbers(uncovered))
    let s:uncoveredRangeList[bufnr] = s:makeRanges(uncovered)
  catch
    echoerr v:exception
  endtry
endfunction

function! s:IstanbulNext(reverse)
  let bufnr = bufnr('%')
  if !has_key(s:uncoveredRangeList, bufnr)
    echoerr 'No instanbul information loaded on current buffer'
    return
  endif
  let rangeList = get(s:uncoveredRangeList, bufnr)
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
  call remove(s:uncoveredRangeList, bufnr)
  exec 'sign unplace * buffer='.bufnr
endfunction
