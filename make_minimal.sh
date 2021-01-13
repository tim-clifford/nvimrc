#!/bin/sh
patch -b .vimrc minimal.patch
mv .vimrc .vimrc-minimal
mv .vimrc.orig .vimrc
