let s:keepcpo = &cpo
set cpo&vim

let g:istanbul#error#messages = {
  \ 'InvalidMode' : '"%s" is invalid mode for InstanbulMode',
  \ 'InvalidPrefix' : 'Prefix contains invalid characters (g:istanbul#quickfix#prefix = %s)',
  \ 'JsonNotFound' : 'coverage.json is not found. (g:istanbul#jsonPath = %s)',
  \ 'JsonUnloaded' : 'No coverage information loaded for current buffer: %s',
  \ 'EntryNotFound' : 'Entry of "%s" is not present on "%s"',
  \ 'NoUncoveredLine' : 'No uncovered line on current buffer: %s',
  \ }

function! istanbul#error#spreadcall(func, args)
  execute printf('return %s(%s)', a:func, join(map(a:args, 'string(v:val)'), ', '))
endfunction

function! istanbul#error#format(key, ...)
  return printf('Istanbul: %s', istanbul#error#spreadcall('printf',
    \ extend([g:istanbul#error#messages[a:key]], a:000)))
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
