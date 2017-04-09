# istanbul.vim

![istanbul.vim](preview.gif)

Visualize code coverage and summarize uncovered lines into quickfix by reading `coverage.json`

Currently, the following JSON output are confirmed:

- [istanbul](https://www.npmjs.com/package/istanbul)
- [nyc --report=json](https://www.npmjs.com/package/nyc)

100% Vim Script:sparkles: Works on Linux, Windows, and Mac OS, including
non-Python(`-python`) and non-Ruby(`-ruby`) environments.

## Requirements

- Vim 7.x + json-ponyfill(http://github.com/retorillo/json-ponyfill.vim)
- OR, Vim >= [7.4.1304](https://github.com/vim/vim/commit/7823a3bd2eed6ff9e544d201de96710bd5344aaf)

## Install (Pathogen)

```bash
git clone https://github.com/retorillo/istanbul.vim.git ~/.vim/bundle/istanbul.vim

# Only for Vim < 7.4.1304
git clone https://github.com/retorillo/json-ponyfill.vim.git ~/.vim/bundle/json-ponyfill.vim
```

## Commands

### IstanbulUpdate

Update signs of current buffer and summarize uncovered lines into
quickfix/location-list by reading `coverage.json`,

```vim
:view index.js | !npm test | IstanbulUpdate
```

By default, `IstanbulUpdate` continues to find `coverage/coverage.json` or
`coverage/coverage-final.json` from current buffer's parent directory(`%:h`)
until the root(`/` for Linux, `<Drive>:\` or `\\<Server>\` for Windows).

To change this search pattern, set `g:istanbul#jsonPath`.

```vim
let g:istanbul#jsonPath = ['coverage/custom.json', 'coverage/coverage.json']
```

Or, execute with existing JSON path.

```vim
IstanbulUpdate coverage/custom.json
```

Uncovered lines are stored to quickfix by default,
use `let g:istanbul#store = 'location-list'` to change store.
See `:help quickfix` and `:help location-list`.

Default mode is line coverage, can change mode by using [IstanbulMode](#istanbulmode).

### IstanbulMode

Change or toggle mode of coverage information of current buffer.
Now supports the following modes:

- `line` (gathered information from `statementMap` and `fnMap`)
- `branch` (gathered information from `branchMap`)

```vim
" Toggle between line and branch coverage
:IstanbulMode
" Change to line coverage
:IstanbulMode line
" Change to branch coverage
:IstanbulMode branch
```

### IstanbulNext, IstanbulBack

Jump to N-th next/previous head of uncovered region.

Basically this plugin use quickfix/location-list, so can use its commands to jump.
(eg. `:cc`, `:cn`, `:cp` )

But, `:IstanbulNext` and `:IstanbulBack` allows to jump to only entry about coverage,
and useful when quickfix/location-list is dirty. (eg. after `:vimgrepadd`)

Without bang(`!`), never jump to another buffer. This rule is same as `:cc`,
see `:help :cc`.

When reached end of buffer, by default, jump cyclically without error.
To change this behavior, execute `let g:istanbul#jumpStrategy = 'linear'`

```vim
" Jump to next uncoveraged range
:IstanbulNext
" Jump to 12th uncovered range
:12 IstanbulNext
" Same as above
:IstanbulNext 12
" Same as above, but may jump to another buffer
:IstanbulNext! 12

" Jump to previous uncoveraged range
:IstanbulBack
" Jump to N-th previous uncoveraged range
:12 IstanbulNext
" Same as above
:IstanbulNext 12
" Same as above, but may jump to another buffer
:IstanbulNext! 12
```

### IstanbulClear

Clear all signs of current buffer.

If IstanbulClear is called with bang(!), also remove Istanbul entries from
quickfix/location-list on current buffer.

```vim
" Only clear signs
:IstanbulClear
" Clear signs and quickfix/location-list
:IstanbulClear!
```

### IstanbulToggle

Toggle between `:IstanbulUpdate` and `:IstanbulClear!` by keeping its mode and
specified JSON path.

## Unit testing for this plugin script (For plugin developers)

`test/test.vim` is a useful snipet to verify working of autoload scripts.

```vim
: view README.md | view test/test.vim | let g:istanbul#test = 1 | source test/test.vim
" ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
" This test requires at least two valid buffers
```

## License

MIT License

Copyright (C) 2016-2017 Retorillo
