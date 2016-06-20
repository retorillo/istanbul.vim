# istanbul.vim

![istanbul.vim](preview.gif)

Code coverage visualizer for [istanbul](https://www.npmjs.com/package/istanbul)
`coverage.json`

Works on Linux, Windows and Mac OS.

No python is needed. 100% VimL :sparkles:

## Install (Pathogen)

```
git clone https://github.com/retorillo/istanbul.vim.git ~/.vim/bundle/istanbul.vim
```

## Commands

| Keymaps             | Commands                          |
|---------------------|-----------------------------------|
| `Ctrl-I` + `Ctrl-I` | [IstanbulUpdate](#istanbulupdate) |
| `Ctrl-I` + `Ctrl-N` | [IstanbulNext](#istanbulnext)     |
| `Ctrl-I` + `Ctrl-B` | [IstanbulBack](#istanbulback)     |
| `Ctrl-I` + `Ctrl-D` | [IstanbulClear](#istanbulclear)   |

### IstanbulUpdate

Update signs of current buffer from 'coverage/coverage.json'

```
:wall | !npm test | IstanbulUpdate
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

## Options

The following options can be specified on your `~/.vimrc`

```
" Disable keymaps
let g:istanbul#disableKeymaps = 1
```

## License

Distributed under the MIT license

Copyright (C) 2016 Retorillo
