command! -nargs=0 Istanbul call s:IstanbulUpdate()
command! -nargs=0 IstanbulClear call s:IstanbulClear()

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
    for key in keys(statementMap)
      let item = get(statementMap, key)
      let c = str2nr(get(s, key))
      let start = get(get(item, 'start'), 'line')
      call s:signCoverage(start, c, bufnr)
    endfor
    for key in keys(fnMap)
      let item = get(fnMap, key)
      let c = str2nr(get(f, key))
      let line = get(item, 'line')
      call s:signCoverage(line, c, bufnr)
    endfor
  catch
    echoerr v:exception 
  endtry
endfunction

function! s:IstanbulClear()
  exec 'sign unplace *'
endfunction
