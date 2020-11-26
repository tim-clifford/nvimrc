set nocompatible              " be iMproved, required
filetype off                  " required
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'
Plugin 'valloric/youcompleteme'
Plugin 'sirver/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'scrooloose/nerdcommenter'
Plugin 'lervag/vimtex'
Plugin 'dracula/vim', { 'name': 'dracula' }
Plugin 'tim-clifford/jupyter-vim'
Plugin 'tim-clifford/jupytext.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'lambdalisue/battery.vim'
Plugin 'puremourning/vimspector'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
"Plugin 'pandysong/ghost-text.vim', { 'do': ':GhostInstall' }

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" General {{{
syntax enable
colorscheme dracula
hi Normal ctermbg=NONE
set foldmethod=marker
set mouse=a
let mapleader = " "
let maplocalleader = " "
command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		\ | wincmd p | diffthis
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set number
augroup numbertoggle
	autocmd BufEnter,FocusGained * set relativenumber
	autocmd BufLeave,FocusLost   * set norelativenumber
augroup END
set noshowmode
set shortmess+=F
"let g:terminal_ansi_colors = [ "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#f8f8f2", "#6272a4", "#ff6e6e", "#69ff94", "#ffffa5", "#d6acff", "#ff92df", "#a4ffff", "#ffffff", "#21222c" ]

" }}}
" NERDTree {{{
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" }}}
" TermPDF {{{
let g:current_page = 0
let g:total_pages = 0
let g:termpdf_lastcalled = 0
function TermPDF(file) abort
	" Implement some basic throttling
	let time = str2float(reltimestr(reltime())) * 1000.0
	if time - g:termpdf_lastcalled > 1000
		call system('kitty @ kitten termpdf.py ' . a:file)
		" Remember the last opened page but don't fail when the number of
		" pages has changed
		let g:total_pages = str2nr(system("pdfinfo " . a:file . " | grep Pages | sed 's/[^0-9]*//'"))
		if g:current_page == 0
			let g:current_page = 1
		elseif g:current_page <= g:total_pages
			call system('sleep 0.2 && tpdfc goto ' . g:current_page)
		else
			let g:current_page = 1
		endif
		let g:termpdf_lastcalled = time
	endif
endfunction

function TermPDFNext() abort
	if g:current_page < g:total_pages
		call system('tpdfc forward 1')
		let g:current_page += 1
	endif
endfunction

function TermPDFPrev() abort
	if g:current_page > 1
		call system('tpdfc back 1')
		let g:current_page -= 1
	endif
endfunction

function TermPDFEnd() abort
	call system('tpdfc last')
endfunction

function TermPDFClose() abort
	call system('kitty @ close-window --match title:termpdf')
endfunction
function TermPDFAutoUpdateIfChanged(timer)
	if filereadable(getcwd().'/.jupyter-pdf-changed')
		call TermPDF(getcwd().'/jupyter_plots.pdf')
		call system('rm '.getcwd().'/.jupyter-pdf-changed')
		if g:current_page < g:total_pages
			call TermPDFEnd()
		endif
	endif
endfunction
let g:timerid = -1
function TermPDFAutoUpdateStart()
	if g:timerid == -1
		let g:timerid = timer_start(1000, 'TermPDFAutoUpdateIfChanged', {'repeat': -1})
	endif
endfunction
function TermPDFAutoUpdateStop()
	if g:timerid != -1
		timer_stop(g:timerid)
	endif
endfunction
" }}}
" Vimtex {{{
let g:tex_flavor = 'latex'
let g:vimtex_view_automatic = 0
function VimtexCallback()
	call TermPDF(escape(b:vimtex.out()," "))
endfunction
function VimtexExit()
	call TermPDFClose()
	:VimtexClean
	" Remove extra auxiliary files that I don't particularly care about
	call system("rm *.run.xml *.bbl *.synctex.gz")
endfunction
augroup vimtex
	autocmd VimLeave *.tex call VimtexExit()
	autocmd User VimtexEventCompileSuccess call VimtexCallback()
	autocmd InsertLeave *.tex :w
	" <C-PgUp> and <C-PgDn>
	autocmd FileType tex,markdown nnoremap [5;5~ :call TermPDFPrev()<CR>
	autocmd FileType tex,markdown nnoremap [6;5~ :call TermPDFNext()<CR>
	autocmd FileType markdown call TermPDFAutoUpdateStart()
augroup END
" }}}
" Jupyter {{{
function JupyterStart()
	call system('kitty @ kitten jupyter.py '.getcwd())
	:JupyterConnect
endfunction
function JupyterExit()
	call TermPDFClose()
	call system('pkill -9 jupyter && kitty @ close-window --match title:vimjupyter')
endfunction
function JupyterCompile()
	silent execute "w"
	call system('pandoc '.expand('%:t:r').'.md -o jupyter_notebook.pdf -V geometry:margin=1in')
	call TermPDF(getcwd().'/jupyter_notebook.pdf')
endfunction
"function JupyterRunAllIntoMarkdown()
	""call system('pkill -9 jupyter')
	""call JupyterStart()
	"normal gg
	"let flags = "c"
	"while search("```python", flags) != 0
		"call jupyter#SendCell()
		"call search("```")
		"call system("sleep 0.5")
		"call append(line('.'),matchstr(readfile('.jupyter-out'),"OUT["))
		"let flags = ""
	"endwhile
"endfunction
"let g:jupyter_monitor_console = 1
let g:jupyter_mapkeys = 0
let b:jupyter_kernel_type = 'python'
let g:jupyter_cell_separators = ['```py','```']
let g:markdown_fenced_languages = ['python']
augroup jupyter
	autocmd VimLeave *.ipynb call JupyterExit()
	autocmd BufEnter *.ipynb call jupyter#load#MakeStandardCommands()
	autocmd BufEnter *.ipynb set filetype=markdown.python
augroup END
" }}}
" YouCompleteMe {{{
au VimEnter * let g:ycm_semantic_triggers.tex=g:vimtex#re#youcompleteme
let g:ycm_filetype_blacklist={'notes': 1, 'unite': 1, 'tagbar': 1, 'pandoc': 1, 'qf': 1, 'vimwiki': 1, 'text': 1, 'infolog': 1, 'mail': 1}
" }}}
" Make {{{
function MakeAndRun()
	if filereadable('start.sh')
		call system('./start.sh >stdout.txt 2>stderr.txt&')
	elseif expand('%:e') == python
		call system('python3 '.expand('%:t').'>stdout.txt 2>stderr.txt&')
	else
		" Assumes makefile exists and binary filename is current filename
		" minus extension
		:!make
		call system('./'.expand('%:r').'>stdout.txt 2>stderr.txt&')
	endif
endfunction
" }}}
" Keyboard Mappings {{{
" General {{{
noremap n h
noremap <C-W>n <C-W>h
noremap N H
noremap <C-W>N <C-W>H
noremap e j
noremap <C-W>e <C-W>j
noremap E J
noremap <C-W>E <C-W>J
noremap i k
noremap <C-W>i <C-W>k
noremap I K
noremap <C-W>I <C-W>K
noremap o l
noremap <C-W>o <C-W>l
noremap O L
noremap <C-W>O <C-W>L
noremap k o
noremap <C-W>k <C-W>o
noremap K O
noremap <C-W>K <C-W>O
noremap l e
noremap <C-W>l <C-W>e
noremap L E
noremap <C-W>L <C-W>E
noremap h i
noremap <C-W>h <C-W>i
noremap H I
noremap <C-W>H <C-W>I
noremap j n
noremap <C-W>j <C-W>n
noremap J N
noremap <C-W>J <C-W>N
noremap <Leader>k za
" }}}
" Make {{{
noremap <Leader>mm :wa <bar> make <CR>
noremap <Leader>mr :wa <bar> call MakeAndRun() <CR>
" }}}
" Terminal {{{
tnoremap <Esc> <C-\><C-n>
tnoremap <Esc><Esc> <C-\><C-n>
set timeout timeoutlen=1000  " Default
set ttimeout ttimeoutlen=100  " Set by defaults.vim
noremap <Leader>tt :call term_start($SHELL, {'curwin' : 1})<CR>
noremap <Leader>ts :term<CR>
noremap <Leader>tv :vertical term<CR>
" }}}
" {{{ NERDTree
noremap <Leader>n  :NERDTreeToggle<CR>
let g:NERDTreeMapActivateNode='k'
let g:NERDTreeMapOpenSplit='s'
let g:NERDTreeMapOpenVSplit='v'
let g:NERDTreeMapToggleHidden='H'
let g:NERDTreeMapOpenRecursively='0'
let g:NERDTreeMapOpenExpl='l'
" }}}
" Ultisnips {{{
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
" }}}
" Vimtex {{{
nnoremap <Leader>lx :call TermPDFClose()<CR>
" }}}
" Jupyter {{{
" Run current file
nnoremap <leader>jr :JupyterRunFile<CR>
nnoremap <leader>ji :PythonImportThisFile<CR>

" Change to directory of current file
nnoremap <leader>jd :JupyterCd %:p:h<CR>

" Send a selection of lines
nnoremap <leader>jx :call jupyter#SendCell() <bar> /```py<CR>
nnoremap <leader>je :JupyterSendRange<CR>
nmap     <leader>je <Plug>JupyterRunTextObj
vmap     <leader>je <Plug>JupyterRunVisual

nnoremap <leader>ju :JupyterUpdateShell<CR>

" Debugging maps
nnoremap <leader>jb :PythonSetBreak<CR>

" Kitty side panel
nnoremap <leader>jj :call JupyterStart()<CR>
nnoremap <leader>jp :call JupyterCompile()<CR>
nnoremap <leader>jq :call JupyterExit()<CR>

" goto cell
nnoremap <leader>jc /```py<CR>
nnoremap <leader>jC ?```py<CR>
" run all
nnoremap <leader>ja :%g/```py/JupyterSendCell<CR>G
" }}}
" YouCompleteMe {{{
" Avoid confilict with vimspector
let ycm_key_detailed_diagnostics = '<leader>yd'
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
" fzf {{{
nnoremap <leader>f :GFiles<CR>
nnoremap <leader>F :Files<CR>
" }}}
" Fugitive {{{
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
