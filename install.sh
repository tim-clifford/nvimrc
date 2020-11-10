#!/bin/bash
git submodule init
git submodule update
ln -s .vimrc $HOME 
ln -s .vim $HOME
ln -s .vim/bundle/jupyter-vim/ipython-magic/plot_to_pdf.py $HOME/.ipython/profile_default/startup

