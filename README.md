# istanbul.vim

![istanbul.vim](preview.gif)

Code coverage visualizer for [istanbul](https://www.npmjs.com/package/istanbul)
`coverage.json`. Now supports line coverage like [Coveralls](https://coveralls.io),
plus branch coverage.

100% Vim Script! Works on Linux, Windows, and Mac OS, including
non-Python(`-python`) and non-Ruby(`-ruby`) environments.

## Requirements

- Vim 7.x + json-ponyfill(http://github.com/retorillo/json-ponyfill.vim)
- OR, Vim >= 7.4.1154 (Supports JSON natively)

## Install (Pathogen)

```bash
git clone https://github.com/retorillo/istanbul.vim.git ~/.vim/bundle/istanbul.vim

# optional (only if your Vim does not support JSON natively)
git clone https://github.com/retorillo/json-ponyfill.vim.git ~/.vim/bundle/json-ponyfill.vim
```

## Commands

### IstanbulUpdate

Update signs of current buffer by reading `coverage.json`

```vim
:wall | !npm test | IstanbulUpdate
```

By default, `IstanbulUpdate` continues to find `coverage/coverage.json` or
`coverage/coverage-final.json` from current buffer's parent directory(`%:h`)
until the root(`/` for Linux, `<Drive>:\` or `\\<Server>\` for Windows).

To change this behavior, set `g:istanbul#jsonPath`.

```vim
let g:istanbul#jsonPath = ['coverage/custom.json', 'coverage/coverage.json']
```

Or, execute `IstanbulUpdate` with existing JSON path.

```vim
IstanbulUpdate coverage/custom.json
```

Visualization mode is line coverage information like Coveralls by default.
Can toggle mode by using [IstanbulMode](#istanbulmode).

### IstanbulMode

Change or toggle visualization mode of coverage information of current buffer.
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

### IstanbulNext

Jump to N-th next head of uncovered range.

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
```

### IstanbulBack

Jump to N-th previous head of uncovered range.

Without bang(`!`), never jump to another buffer. This rule is same as `:cc`,
see `:help :cc`.

When reached beginning of buffer, by default, jump cyclically without error.
To change this behavior, execute `let g:istanbul#jumpStrategy = 'linear'`

```vim
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
QuickFix list on current buffer.

```vim
" Only clear signs
:IstanbulClear
" Clear signs and Quickfix
:IstanbulClear!
```

## Unit testing for this plugin script (For plugin developers)

`test/test.vim` is a useful snipet to verify working of autoload scripts.

```vim
wall | let g:istanbul#test = 1 | source test/test.vim
```

## License

The MIT License

Copyright (C) 2016-2017 Retorillo
