# istanbul.vim

![istanbul.vim](preview.gif)

Code coverage visualizer for [istanbul](https://www.npmjs.com/package/istanbul)
`coverage.json`. Now supports line coverage like [Coveralls](https://coveralls.io),
plus branch coverage.

100% Vim Script! Works on Linux, Windows, and Mac OS, including
non-Python(`-python`) and non-Ruby(`-ruby`) environments. 

## Requirements

- Vim 7.x + json-ponyfill(http://github.com/retorillo/json-ponyfill.vim)
- OR Vim >= 7.4.1154 (Supports JSON natively)

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
until the root directory(`/` for Linux, drive letter for Windows).

To change this behavior, set `g:istanbul#jsonPath`.

```vim
let g:istanbul#jsonPath = ['coverage/custom.json', 'coverage/coverage.json']
```

Or, execute `IstanbulUpdate` with existing JSON path.

```vim
IstanbulUpdate coverage/custom.json
```

By default, line coverage information like [Coveralls](https://coveralls.io/).  
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

Jump to next first line of uncovered range

```vim
:IstanbulNext
```

### IstanbulBack

Jump to previous first line of uncovered range

```vim
:IstanbulBack
```

### IstanbulClear

Clear all signs of current buffer

```vim
:IstanbulClear
```

## Unit testing for this plugin script (For plugin developers)

`test/test.vim` is a useful snipet to verify working of autoload scripts.

```vim
wall | let g:istanbul#test = 1 | source test/test.vim
```

## License

The MIT License

Copyright (C) 2016-2017 Retorillo
