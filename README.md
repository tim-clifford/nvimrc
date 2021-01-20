# Personal Vim configs

### Warning!

I use my own keyboard layout (based on colemak) so there are many mappings in
here which don't make sense for most people.

### Versions

I am maintaining multiple versions of this config for a few reasons:

- Installing all my plugins takes a long time, so it's nice to also have
  functional minimal configs

- Some nice things require nvim, such as firenvim (vim inside firefox)

- [vimrc-tiny](./.vimrc-tiny) is a nice reference for making mappings in other
  vim-like programs with my keyboard layout

I maintain patch files for these instead of full configs because it makes it
easier for me to just modify my main config on the fly and use that to update
the other configs as necessary. It also stops me from neglecting the other
configs. There are several helper scripts in this repo to deal with them.

### Installing

install.sh will install the main vimrc by symlinking it from wherever this
repository is to $HOME and moving any original vimrc to $HOME/.vimrc.orig .
Vundle is cloned into .vim and plugins are installed automatically. I like to
keep this repository in .vim/git so it doesn't get accidentally deleted.
