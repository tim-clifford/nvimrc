" Plugins {{{
set nocompatible
filetype off
set rtp+=~/.config/nvim/bundle/Vundle.vim
call vundle#begin('~/.config/nvim/bundle')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" General stuff
Plugin 'dracula/vim', { 'name': 'dracula' }
Plugin 'skywind3000/asyncrun.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'vim-airline/vim-airline'
Plugin 'puremourning/vimspector'
Plugin 'junegunn/vim-emoji'

" Neovim stuff
Plugin 'neovim/nvim-lspconfig'
Plugin 'nvim-lua/completion-nvim'
Plugin 'tjdevries/nlua.nvim'
Plugin 'tjdevries/lsp_extensions.nvim'
Plugin 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plugin 'nvim-lua/popup.nvim'
Plugin 'nvim-lua/plenary.nvim'
Plugin 'nvim-telescope/telescope.nvim'
Plugin 'pwntester/octo.nvim'

" Git
Plugin 'tpope/vim-fugitive'

" Snippets
Plugin 'sirver/ultisnips'
Plugin 'honza/vim-snippets'

" Functionality
Plugin 'lervag/vimtex'
Plugin 'tim-clifford/jupytext.vim'
Plugin 'tim-clifford/vim-venus'
Plugin 'tim-clifford/vim-qalc'
Plugin 'tim-clifford/vim-dirdiff'
Plugin 'dhruvasagar/vim-table-mode'
Plugin 'thinca/vim-ref'

" Syntax
Plugin 'chikamichi/mediawiki.vim'
Plugin 'vim-pandoc/vim-pandoc-syntax'
Plugin 'dag/vim-fish'
Plugin 'ap/vim-css-color'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'powerman/vim-plugin-AnsiEsc'
Plugin 'tkztmk/vim-vala'

" External
Plugin 'glacambre/firenvim'

call vundle#end()
filetype plugin indent on
" }}}
" General {{{
" Colors
syntax         enable
colorscheme    dracula
highlight      Normal ctermbg=NONE
highlight      Normal guibg=NONE
set            termguicolors

" Formatting
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set textwidth=79
augroup formatting
	autocmd!
	autocmd BufWritePre * call TrimWhitespace()
augroup END

" Visual
set incsearch nohlsearch
set foldmethod=marker
set noshowmode
set nowrap
set number
set guicursor=

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

fun! SetRelativenumber()
	" Help files don't get numbering so without this check we'll get an
	" annoying shift in the text when going in and out of a help buffer
	if &filetype != "help"
		set relativenumber
	endif
endfun
autocmd BufEnter,FocusGained * call SetRelativenumber()
autocmd BufLeave,FocusLost   * set norelativenumber
set scrolloff=8
set signcolumn=yes
set colorcolumn=80,120

" Misc
set undodir=~/.local/share/nvim/undo
set undofile
set hidden
set shortmess+=F

" Avoid showing message extra message when using completion
set shortmess+=c

command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		\ | wincmd p | diffthis
command! Cd cd %:p:h
" }}}
" Cheatsheet {{{
command! -nargs=+ Help :call Help(<q-args>)
fun! Help(args)
	let argsl = split(a:args, ' ')
	execute 'AsyncRun -mode=terminal curl cht.sh/'.argsl[0].'/'.join(argsl, '+')
endfun
" }}}
" Modeline {{{
" https://vim.fandom.com/wiki/Modeline_magic
" Append modeline after last line in buffer.
" Use substitute() instead of printf() to handle '%%s' modeline in LaTeX
" files.
function! AppendModeline()
  let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
        \ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
  let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
  call append(line("$"), l:modeline)
endfunction
command AppendModeline call AppendModeline()
" }}}
" Make {{{
let g:asyncrun_open=10
autocmd! BufWritePost $MYVIMRC nested source %
execute 'autocmd! BufWritePost '.$HOME.'/.vim/git/.vimrc-nvim nested source %'
fun! MakeAndRun()
	if filereadable('start.sh')
		:AsyncStop
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		:AsyncRun ./start.sh
	elseif &filetype == 'python'
		:AsyncStop
		execute ':AsyncRun python3 '.expand('%:t')
	elseif &filetype == 'sh'
		:AsyncStop
		execute ':AsyncRun ./'.expand('%:t')
	elseif &filetype == 'markdown'
		:AsyncStop
		call venus#Make()
	else
		" Assumes makefile exists and binary filename is current filename
		" minus extension
		:AsyncRun make
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		call system('./'.expand('%:r').'>stdout.txt 2>stderr.txt&')
	endif
endfun
fun! Make()
	if &filetype == 'markdown'
		call venus#PandocMake()
	else
		:make
	endif
endfun
" }}}
" Project Specific {{{
" Config {{{
fun! ConfigGitHelper(arg)
	if substitute(getcwd(), '.*/', '', '') == '.config'
		if filereadable("gith.sh")
			execute "AsyncRun ./gith.sh --".a:arg
		else
			echo "git helper not readable"
		endif
	else
		echo "Not in config directory"
	endif
endfun
fun! ConfigInstaller(arg)
	if substitute(getcwd(), '.*/', '', '') == '.config'
		if filereadable("install.sh")
			execute "AsyncRun ./install.sh --".a:arg
		else
			echo "installer not readable"
		endif
	else
		echo "Not in config directory"
	endif
endfun
" }}}
" Website {{{
fun! BlogInit(title)
	let name = join(split(system("echo -n '".
					\ tolower(a:title)
					\."' | tr -d '[:punct:]'")
				\, ' '), '-')
	let fname = 'blog/'.name.'.md'

	cd ~/projects/tim.clifford.lol
	execute 'term firefox localhost:3000/blog/'.name.' & npm run dev'

	if ! filereadable(fname)
		" This is a bit awkward unfortunately
		execute 'edit ' . fname
		let header = [
					\ '---',
					\ 'title: "'.a:title.'"',
					\ 'excerpt: ""',
					\ 'createdAt: "'.system("date +'%Y-%m-%d' | tr -d '\n'").'"',
					\ 'updatedAt: "'.system("date +'%Y-%m-%d' | tr -d '\n'").'"',
					\ 'author:',
					\ '  name: Tim Clifford',
					\ '  avatar: "https://github.com/tim-clifford.png?size=48"',
					\ 'ogImage: ""',
					\ 'color: ""',
					\ '---',
					\ '',
				\]

		call append(0, header)
		call append('$', "<!-- vi: set sts=2 sw=2 et :-->")
		norm! Gkk
	else
		execute 'edit ' . fname
	endif
endfun
fun! BlogPublish() abort
	" sanity checks
	if match(expand("%:p"), "tim\.clifford\.lol/blog/.*\.md") == -1
		echom "Not a valid path"
		return 1
	endif
	!npm run all
	execute '!'.substitute(expand('%:p'), 'blog\/[^/]*\.md$',
				\ 'scripts\/sendmail.sh ', '') . expand('%')
endfun
fun! WebInit()
	cd ~/projects/tim.clifford.lol
	term firefox localhost:3000 & npm run dev
	edit pages/index.js
endfun
fun! WebPublishAndCommit()
	AsyncRun npm run all
	Gstatus
endfun
command! -nargs=+ Blog :call BlogInit(<q-args>)
command! BlogPublish :call BlogPublish()
command! Web :call WebInit()
command! WebPublish :call WebPublishAndCommit()
" }}}
" }}}
" Plugin Config {{{
" Vimtex {{{
fun! VimtexCallback()
	echo "TODO: Make this open zathura"
endfun
fun! VimtexExit()
	:VimtexClean
	" Remove extra auxiliary files that I don't particularly care about
	call system("rm *.run.xml *.bbl *.synctex.gz")
endfun
augroup vimtex
	autocmd VimLeave *.tex call VimtexExit()
	autocmd User VimtexEventCompileSuccess call VimtexCallback()
	autocmd InsertLeave *.tex :w
augroup END
let g:vimtex_view_automatic = 0
" }}}
" Venus {{{
let g:pandoc_defaults_file   = '~/.config/pandoc/pandoc.yaml'
let g:pandoc_header_dir      = '~/.config/pandoc/headers'
let g:pandoc_highlight_file  = '~/.config/pandoc/dracula.theme'
let g:pandoc_options         = '-V geometry:margin=1in '
let g:venus_ignorelist       = ['README.md', 'tim.clifford.lol/blog']
" }}}
" Airline {{{
let g:airline#extensions#whitespace#mixed_indent_algo = 2
" }}}
" Codi {{{
fun! s:qalc_preproc(line)
	return substitute(a:line, '\n', '', 'g')
endfun
let g:codi#interpreters = {
	\ 'qalc': {
		\ 'bin': 'qalc',
		\ 'prompt': '^> ',
		\ 'preprocess': function('s:qalc_preproc'),
		\ },
	\ }
" }}}
" Lspconfig {{{
lua require('lspconfig').jedi_language_server.setup{}
lua require('lspconfig').bashls.setup{}
lua require('lspconfig').tsserver.setup{}
lua require('lspconfig').vimls.setup{}
lua require('lspconfig').clangd.setup{}
" }}}
" Completion {{{
autocmd BufEnter * lua require('completion').on_attach()
" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

let g:completion_enable_snippet = 'UltiSnips'
" }}}
" Telescope {{{
lua require('telescope').load_extension('octo')
" }}}
" }}}
" Keyboard Mappings {{{
" General {{{
let mapleader = " "
let maplocalleader = " "
nnoremap <leader>v<leader> :edit ~/.config/nvim/init.vim<CR>
" Why is this not default, I don't get it
noremap Y y$

noremap n h
noremap N H
noremap e j
noremap E J
noremap i k
noremap I K
noremap o l
noremap O L
noremap k o
noremap K O
noremap l e
noremap L E
noremap h i
noremap H I
noremap j n
noremap J N
noremap <leader>k za
" }}}
" Clipboard {{{
nnoremap <leader>pa ggdG"+p
nnoremap <leader>pi ggdG"+p:Indent<CR>
nnoremap <leader>ya gg"+yG
" }}}
" Format {{{
nnoremap <leader>o :call   AlignWhitespaceFile('  ',' ','\t')<CR>
" Let the strategy be more aggressive for visual selection
vnoremap <leader>o :call AlignWhitespaceVisual('  ',' ','  \|\t')<CR>
noremap <leader>i :Indent<CR>
" }}}
" Splits {{{
noremap <leader>s  <C-W>
noremap <leader>ss <C-W>s<C-W>j
noremap <leader>sv <C-W>v<C-W>l
noremap <leader>sn <C-W>h
noremap <leader>sN <C-W>H
noremap <leader>se <C-W>j
noremap <leader>sE <C-W>J
noremap <leader>si <C-W>k
noremap <leader>sI <C-W>K
noremap <leader>so <C-W>l
noremap <leader>sO <C-W>L
noremap <leader>sk <C-W>o
noremap <leader>sK <C-W>O
noremap <leader>sl <C-W>e
noremap <leader>sL <C-W>E
noremap <leader>sh <C-W>i
noremap <leader>sH <C-W>I
noremap <leader>sj <C-W>n
noremap <leader>sJ <C-W>N
" }}}
" Make {{{
noremap <Leader>mm :wa <bar> call Make() <CR>
noremap <Leader>mr :wa <bar> call MakeAndRun() <CR>
" }}}
" Terminal {{{
tnoremap <Esc> <C-\><C-n>
tnoremap <Esc><Esc> <C-\><C-n>
set timeout timeoutlen=1000  " Default
set ttimeout ttimeoutlen=100  " Set by defaults.vim
noremap <Leader>tt :call termopen('zsh')<CR>
noremap <Leader>ts :term<CR>
noremap <Leader>tv :vertical term<CR>
" }}}
" Location/Quickfix List {{{
nnoremap <leader>l :call ToggleList(0)<CR>
nnoremap <leader>q :call ToggleList(1)<CR>

" Thanks prime
let g:qfix_open = 0
let g:loclist_open = 0
fun! ToggleList(global)
    if a:global
        if g:qfix_open == 1
            let g:qfix_open = 0
            cclose
        else
            let g:qfix_open = 1
            copen
        end
    else
        if g:loclist_open == 1
            let g:loclist_open = 0
            lclose
        else
            let g:loclist_open = 1
            lopen
        end
    endif
endfun

" }}}
" LSP {{{
" The original g commands are whack, seriously
nnoremap gd :lua vim.lsp.buf.definition()<CR>
nnoremap gi :lua vim.lsp.buf.implementation()<CR>
nnoremap gs :lua vim.lsp.buf.signature_help()<CR>
nnoremap gr :lua vim.lsp.buf.rename()<CR>
nnoremap gl :call LSP_open_loclist()<CR>
nnoremap gn :lua vim.lsp.diagnostic.goto_next()<CR>

fun! LSP_open_loclist()
	lua vim.lsp.diagnostic.set_loclist()
	let g:loclist_open = 1
endfun

" }}}
" Plugin Keymaps {{{
" Emoji {{{
set completefunc=emoji#complete
" Replace emoji with utf-8
nnoremap <leader>e :%s/:\([^ :]\+\):/\=emoji#for(submatch(1), submatch(0))/g<CR>
" Start emoji completion automatically
inoremap : :<C-X><C-U>
" }}}
" Ultisnips {{{
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
" }}}
" Vimspector {{{
nnoremap <leader>dd :call vimspector#Launch()<CR>
nmap <leader>d<space>  <Plug>VimspectorContinue
nmap <leader>ds <Plug>VimspectorStop
nmap <leader>dr <Plug>VimspectorRestart
nmap <leader>dp <Plug>VimspectorPause
nmap <leader>dbb <Plug>VimspectorToggleBreakpoint
nmap <leader>dbc <Plug>VimspectorToggleConditionalBreakpoint
nmap <leader>dbf <Plug>VimspectorAddFunctionBreakpoint
nmap <leader>de <Plug>VimspectorStepOver
nmap <leader>do <Plug>VimspectorStepInto
nmap <leader>di <Plug>VimspectorStepOut
nmap <leader>dc <Plug>VimspectorRunToCursor
nmap <leader>dq :VimspectorReset<CR>
" }}}
" Telescope {{{
nnoremap <leader>f  <cmd>Telescope git_files<CR>
nnoremap <leader>F  <cmd>Telescope find_files<CR>
nnoremap <leader>b  <cmd>Telescope buffers<CR>
nnoremap <leader>ps <cmd>Telescope grep_string<CR>
" }}}
" Fugitive {{{
augroup Fugitive
	autocmd!
	autocmd FileType fugitive
				\ nnoremap <buffer> tr :call ConfigGitHelper("reset")<CR>
	autocmd FileType fugitive
				\ nnoremap <buffer> tp :call ConfigGitHelper("push")<CR>
	autocmd FileType fugitive
				\ nnoremap <buffer> tg :call ConfigGitHelper("pull")<CR>
	autocmd FileType fugitive
				\ nnoremap <buffer> tu :call ConfigInstaller("update")<CR>
augroup END
noremap <leader>g :Gstatus<CR>
let g:nremap = {
\	'o': 'k',
\	'O': 'K',
\	'e': 'l',
\	'E': 'L',
\	'i': 'h',
\	'I': 'H',
\	'n': 'j',
\	'N': 'J',
\}
let g:oremap = {
\	'o': 'k',
\	'O': 'K',
\	'e': 'l',
\	'E': 'L',
\	'i': 'h',
\	'I': 'H',
\	'n': 'j',
\	'N': 'J',
\}
let g:xremap = {
\	'o': 'k',
\	'O': 'K',
\	'e': 'l',
\	'E': 'L',
\	'i': 'h',
\	'I': 'H',
\	'n': 'j',
\	'N': 'J',
\}
" }}}
" }}}
" }}}
