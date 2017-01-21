# istanbul.vim

![istanbul.vim](preview.gif)

Code coverage visualizer for [istanbul](https://www.npmjs.com/package/istanbul)
`coverage.json`. Now supports line coverage like [Coveralls](https://coveralls.io),
plus branch coverage.

Works on Linux, Windows and Mac OS.

No python is needed. 100% VimL :sparkles:

## Requirements

- Vim >= 7.4.1154 (Supports JSON natively)
  - OR install additionaly my JSON plugin http://github.com/retorillo/json-polyfill.vim

## Install (Pathogen)

```bash
git clone https://github.com/retorillo/istanbul.vim.git ~/.vim/bundle/istanbul.vim

# optional (only if your Vim does not support JSON natively)
git clone https://github.com/retorillo/json-ponyfill.vim.git ~/.vim/bundle/json-ponyfill.vim
```

## Commands

### IstanbulUpdate

Update signs of current buffer from 'coverage/coverage.json'
By default, visualize statement and function coverage information like
[Coveralls](https://coveralls.io/).  
Can toggle mode by using [IstanbulMode](#istanbulmode).

```
:wall | !npm test | IstanbulUpdate
```

### IstanbulMode

Change or toggle visualization mode of coverage information of current buffer.
Now supports the following modes:

- `line` (gathered information from `statementMap` and `fnMap`)
- `branch` (gathered information from `branchMap`)

```
" Toggle between line and branch coverage
:IstanbulMode
" Change to line coverage
:IstanbulMode line
" Change to branch coverage
:IstanbulMode branch
```

### IstanbulNext

Jump to next first line of uncovered range

```
:IstanbulNext
```

### IstanbulBack

Jump to previous first line of uncovered range

```
:IstanbulBack
```

### IstanbulClear

Clear all signs of current buffer

```
:IstanbulClear
```

## License

Distributed under the MIT license

Copyright (C) 2016 Retorillo
