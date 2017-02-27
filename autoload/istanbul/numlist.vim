let s:keepcpo = &cpo
set cpo&vim

function! istanbul#numlist#uniq(list)
  let d = {}
  for i in a:list
    let d[i] = 1
  endfor
  return map(keys(d), 'str2nr(v:val)')
endfunction

function! istanbul#numlist#sort(list)
  let len = len(a:list)
  let i1 = 0
  while i1 < len
    let min = a:list[i1]
    let i2 = i1
    let i3 = i1
    while i2 < len
      if a:list[i2] < min
        let min = a:list[i2] < min ? a:list[i2] : min
        let i3 = i2
      endif
      let i2 += 1
    endwhile
    call istanbul#numlist#swap(a:list, i1, i3)
    let i1 += 1
  endwhile
  return a:list
endfunction

function! istanbul#numlist#swap(arr, i1, i2)
  if a:i1 != a:i2
    let v2 = a:arr[a:i2]
    let a:arr[a:i2] = a:arr[a:i1]
    let a:arr[a:i1] = v2
  endif
  return a:arr
endfunction

function! istanbul#numlist#mkrange(arr)
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

let &cpo = s:keepcpo
unlet s:keepcpo
