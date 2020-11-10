#!/bin/bash
if [ -f $HOME/.vimrc ]; then
	mv $HOME/.vimrc $HOME/.vimrc.orig
fi
ln -s .vimrc $HOME 
vim +PluginInstall +qall
ln -s $HOME/.vim/bundle/jupyter-vim/ipython-magic/plot_to_pdf.py $HOME/.ipython/profile_default/startup
cd $HOME/.vim/bundle/youcompleteme/
python3 install.py --all
cd -
