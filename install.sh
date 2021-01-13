#!/bin/bash
if [ -f $HOME/.vimrc ]; then
	mv $HOME/.vimrc $HOME/.vimrc.orig
fi
if [ -L $HOME/.vimrc ]; then
	rm $HOME/.vimrc
fi
ln -s "$(pwd)/.vimrc" $HOME

if ! [ "$1" = "--no-build" ]; then
	mkdir -p $HOME/.vim/bundle
	git clone --depth 1 \
		https://github.com/VundleVim/Vundle.vim.git \
		$HOME/.vim/bundle/Vundle.vim
	vim +PluginInstall +qall
	vim \
		+'VimspectorInstall --enable-c --enable-python --enable-bash --force-enable-csharp' \
		+'call fzf#install()' \
		+qall
	if [ -d $HOME/.ipython ]; then
		ln -s $HOME/.vim/bundle/jupyter-vim/ipython-magic/plot_to_pdf.py \
			  $HOME/.ipython/profile_default/startup
	fi
	cd $HOME/.vim/bundle/youcompleteme/
	python3 install.py --all
	cd -
fi

if nvim --help >/dev/null; then
	mkdir -p $HOME/.config/nvim
	# Make nvim config from patch
	patch -b .vimrc nvim.patch
	mv .vimrc .vimrc-nvim
	mv .vimrc.orig .vimrc
	# Link nvim config
	if [ -f $HOME/.config/nvim/init.vim ]; then
		mv $HOME/.config/nvim/init.vim $HOME/.config/nvim/init.vim.orig
	fi
	if [ -L $HOME/.config/nvim/init.vim ]; then
		rm $HOME/.config/nvim/init.vim
	fi
	ln -s "$(pwd)/.vimrc-nvim" $HOME/.config/nvim/init.vim
	patch -b .vimrc-nvim nvim-pager.patch
	mv .vimrc-nvim .vimrc-nvim-pager
	mv .vimrc-nvim.orig .vimrc-nvim

	if ! [ "$1" = "--no-build" ]; then
		mkdir -p $HOME/.config/nvim/bundle
		git clone --depth 1 \
			https://github.com/VundleVim/Vundle.vim.git \
			$HOME/.config/nvim/bundle/Vundle.vim
		nvim +PluginInstall +qall
		cd $HOME/.vim/bundle/youcompleteme/
		python3 install.py --all
		cd -
	fi
fi
	

