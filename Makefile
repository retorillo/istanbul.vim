pack:
	if [ ! -d dist ]; then mkdir dist; fi
	cd .. && zip -r istanbul.vim/dist/istanbul.vim.zip istanbul.vim/plugin
	cd .. && unzip -l istanbul.vim/dist/istanbul.vim.zip
