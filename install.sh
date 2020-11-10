#!/bin/bash
git submodule init
git submodule update --recursive
if [ -f $HOME/.vimrc ]; then
	mv $HOME/.vimrc $HOME/.vimrc.orig
fi
if [ -L $HOME/.vimrc ]; then
	rm $HOME/.vimrc
fi
ln -s "$(pwd)/.vimrc" $HOME
if [ ! -d $HOME/.vim ]; then
	mkdir $HOME/.vim
fi
if [ ! -d $HOME/.vim/bundle ]; then
	mkdir $HOME/.vim/bundle
fi
if [ -L $HOME/.vim/bundle/Vundle.vim ]; then
	rm $HOME/.vim/bundle/Vundle.vim
fi
if [ ! -d $HOME/.vim/bundle/Vundle.vim ]; then
	ln -s Vundle.vim $HOME/.vim/bundle
fi
vim +PluginInstall +qall
ln -s $HOME/.vim/bundle/jupyter-vim/ipython-magic/plot_to_pdf.py $HOME/.ipython/profile_default/startup
cd $HOME/.vim/bundle/youcompleteme/
python3 install.py --all
cd -
