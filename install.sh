if ! [ -d $HOME/.config/nvim/bundle/Vundle.vim ]; then
	mkdir -p $HOME/.config/nvim/bundle
	git clone --depth 1 \
		https://github.com/VundleVim/Vundle.vim.git \
		$HOME/.config/nvim/bundle/Vundle.vim
	nvim +PluginInstall +qall
fi


