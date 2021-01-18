#!/bin/sh
if [ -f .vimrc-minimal ]; then
	mv .vimrc-minimal .vimrc-minimal.orig
fi
patch -b .vimrc minimal.patch
mv .vimrc .vimrc-minimal
mv .vimrc.orig .vimrc
