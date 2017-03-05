let s:keepcpo = &cpo
set cpo&vim

let g:istanbul#error#messages = {
  \ 'InvalidMode' : '"%s" is invalid mode for InstanbulMode',
  \ 'InvalidPrefix' : 'Prefix contains invalid characters (g:istanbul#quickfix#prefix = %s)',
  \ 'JsonNotFound' : 'coverage.json is not found. (g:istanbul#jsonPath = %s)',
  \ 'EntryNotFound' : 'Entry of "%s" is not present on "%s"',
  \ 'OutOfQuickfixDesc' : 'Reached the beginning of Quickfix list. (g:istanbul#jumpStrategy = %s)',
  \ 'OutOfQuickfixAsc' : 'Reached the end of Quickfix list. (g:istanbul#jumpStrategy = %s)',
  \ 'EmptyQuickfix' : 'Quickfix list is empty for current buffer.',
  \ }

function! istanbul#error#spreadcall(func, args)
  execute printf('return %s(%s)', a:func, join(map(a:args, 'string(v:val)'), ', '))
endfunction

function! istanbul#error#format(key, ...)
  return printf('Istanbul: %s', len(a:000) == 0
    \ ? g:istanbul#error#messages[a:key]
    \ : istanbul#error#spreadcall('printf',
    \ extend([g:istanbul#error#messages[a:key]], a:000)))
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
