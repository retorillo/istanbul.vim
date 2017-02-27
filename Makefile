pack:
	if [ ! -d dist ]; then mkdir dist; fi
	cd .. && zip -r istanbul.vim/dist/istanbul.vim.zip istanbul.vim/plugin istanbul.vim/autoload
	cd .. && unzip -l istanbul.vim/dist/istanbul.vim.zip
