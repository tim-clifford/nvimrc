#!/usr/bin/dash
if ! ./make_minimal.sh; then
	exit 1
fi
diff -u .vimrc .vimrc-minimal > minimal.patch
if ! ./make_nvim.sh; then
	exit 1
fi
diff -u .vimrc .vimrc-nvim > nvim.patch
diff -u .vimrc-nvim .vimrc-nvim-pager > nvim-pager.patch
exit 0
