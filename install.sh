#!/bin/bash
if [ -f $HOME/.vimrc ]; then
	mv $HOME/.vimrc $HOME/.vimrc.orig
fi
if [ -L $HOME/.vimrc ]; then
	rm $HOME/.vimrc
fi
ln -s "$(pwd)/.vimrc" $HOME

mkdir -p $HOME/.vim/pack/vendor/start
git clone --depth 1 \
	https://github.com/VundleVim/Vundle.vim.git \
	$HOME/.vim/pack/vendor/start/vundle

vim +PluginInstall +qall
if [ -d $HOME/.ipython ]; then
	ln -s $HOME/.vim/bundle/jupyter-vim/ipython-magic/plot_to_pdf.py $HOME/.ipython/profile_default/startup
fi
cd $HOME/.vim/bundle/youcompleteme/
python3 install.py --all
cd -
