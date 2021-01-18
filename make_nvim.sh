#!/bin/dash
mkdir -p $HOME/.config/nvim
# Make nvim config from patch
patch -b .vimrc nvim.patch
if [ -f .vimrc-nvim ]; then
	mv .vimrc-nvim .vimrc-nvim.orig
fi
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
