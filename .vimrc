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
Plugin 'jupyter-vim/jupyter-vim'
Plugin 'goerz/jupytext.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'lambdalisue/battery.vim'
Plugin 'puremourning/vimspector'

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
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set number
set foldmethod=marker
set mouse=a
command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		\ | wincmd p | diffthis
" }}}
" NERDTree {{{
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
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
	call system("rm *.run.xml *.bbl *.synctex.gz")
endfunction
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
let g:jupyter_mapkeys = 0
let b:jupyter_kernel_type = 'python'
let g:jupyter_cell_markers = ['```py','```']
let g:markdown_fenced_languages = ['python']
" }}}
" Auto Commands {{{
augroup General
	autocmd VimLeave *.tex call VimtexExit()
	autocmd VimLeave *.ipynb call JupyterExit()
	autocmd User VimtexEventCompileSuccess call VimtexCallback()
	autocmd InsertLeave *.tex :w
	autocmd FileType tex,markdown nnoremap [5;5~ :call TermPDFPrev()<Enter>
	autocmd FileType tex,markdown nnoremap [6;5~ :call TermPDFNext()<Enter>
	autocmd FileType markdown call TermPDFAutoUpdateStart()
augroup END
au VimEnter * let g:ycm_semantic_triggers.tex=g:vimtex#re#youcompleteme
au BufEnter *.ipynb call jupyter#MakeStandardCommands()
au BufEnter *.ipynb set filetype=markdown.python
" }}}
" YouCompleteMe {{{
let g:ycm_filetype_blacklist={'notes': 1, 'unite': 1, 'tagbar': 1, 'pandoc': 1, 'qf': 1, 'vimwiki': 1, 'text': 1, 'infolog': 1, 'mail': 1}
" }}}
" Make {{{
function MakeAndRun()
	if filereadable('start.sh')
		call system('./start.sh >stdout.txt 2>stderr.txt&')
	else if expand('%:e') == python
		call system('python3 '.expand('%:t').'>stdout.txt 2>stderr.txt&')
	else
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
noremap <Leader>mm :wa <bar> make <Enter>
noremap <Leader>mr :wa <bar> call MakeAndRun() <Enter>
" }}}
" Terminal {{{
tnoremap <Esc> <C-\><C-n>
tnoremap <Esc><Esc> <C-\><C-n>
set timeout timeoutlen=1000  " Default
set ttimeout ttimeoutlen=100  " Set by defaults.vim
noremap <Leader>tt :call term_start($SHELL, {'curwin' : 1})<Enter>
noremap <Leader>ts :term<Enter>
noremap <Leader>tv :vertical term<Enter>
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
nnoremap <Leader>lx :call TermPDFClose()<Enter>
" }}}
" Jupyter {{{
" Run current file
nnoremap <localleader>jr :JupyterRunFile<CR>
nnoremap <localleader>ji :PythonImportThisFile<CR>

" Change to directory of current file
nnoremap <localleader>jd :JupyterCd %:p:h<CR>

" Send a selection of lines
nnoremap <localleader>jx :JupyterSendCell<CR>
nnoremap <localleader>je :JupyterSendRange<CR>
nmap     <localleader>je <Plug>JupyterRunTextObj
vmap     <localleader>je <Plug>JupyterRunVisual

nnoremap <localleader>ju :JupyterUpdateShell<CR>

" Debugging maps
nnoremap <localleader>jb :PythonSetBreak<CR>

" Kitty side panel
nnoremap <localleader>jj :call JupyterStart()<Enter>
nnoremap <localleader>jq :call JupyterExit()<Enter>

" goto cell
nnoremap <localleader>jc /```py<Enter>
" run all
nnoremap <localleader>ja :%g/```py/JupyterSendCell<Enter>G
" }}}
" Vimspector {{{
nnoremap <leader>dd <Plug>VimspectorContinue
nnoremap <leader>ds <Plug>VimspectorStop
nnoremap <leader>dr <Plug>VimspectorRestart
nnoremap <leader>dp <Plug>VimspectorPause
nnoremap <leader>dbb <Plug>VimspectorToggleBreakpoint
nnoremap <leader>dbc <Plug>VimspectorToggleConditionalBreakpoint
nnoremap <leader>dbf <Plug>VimspectorAddFunctionBreakpoint
nnoremap <leader>dso <Plug>VimspectorStepOver
nnoremap <leader>dsi <Plug>VimspectorStepInto
nnoremap <leader>dsO <Plug>VimspectorStepOut
nnoremap <leader>dc <Plug>VimspectorRunToCursor
" }}} 
" }}}
