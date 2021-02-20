" Plugins {{{
set nocompatible              " be iMproved, required
set encoding=utf-8
filetype off                  " required
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'tpope/vim-fugitive'
Plugin 'valloric/youcompleteme'
Plugin 'sirver/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'scrooloose/nerdcommenter'
Plugin 'lervag/vimtex'
Plugin 'dracula/vim', { 'name': 'dracula' }
Plugin 'jupyter-vim/jupyter-vim'
Plugin 'tim-clifford/jupytext.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'lambdalisue/battery.vim'
Plugin 'puremourning/vimspector'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
Plugin 'dag/vim-fish'
Plugin 'metakirby5/codi.vim'
Plugin 'ap/vim-css-color'
Plugin 'skywind3000/asyncrun.vim'
Plugin 'powerman/vim-plugin-AnsiEsc'
Plugin 'tim-clifford/vim-dirdiff'


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" }}}
" General {{{

" This is for smallbrains only
"set mouse=a

" Colors
syntax         enable
colorscheme    dracula
highlight      Normal ctermbg=NONE
highlight      Normal guibg=NONE
set            termguicolors

" Formatting
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set textwidth=0
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
set colorcolumn=80

" Misc
set undodir=~/.vim/undodir
set undofile
set hidden
set shortmess+=F

command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		\ | wincmd p | diffthis
" }}}
" Visual Selection {{{
" public domain code by stack overflow user FocusedWolf
" https://stackoverflow.com/a/6271254
fun! s:get_visual_selection()
	" Why is this not a built-in Vim script function?!
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let lines = getline(line_start, line_end)
	if len(lines) == 0
		return ''
	endif
	let lines[-1] = lines[-1][:column_end - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][column_start - 1:]
	return join(lines, "\n")
endfun
" }}}
" Maths {{{
fun! DoMathsSubstitute()
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let res = system("qalc -t '".s:get_visual_selection()."'|tr -d '\n'")
	exe "norm ".line_start."G".column_start."|v"
	          \.line_end  ."G".column_end  ."|c".res
endfun
fun! DoMathsQuickfix()
	execute "term qalc '".s:get_visual_selection()."'; exit; read -p x"
	"execute "term sh -c 'qalc '".'"'."'".'"'."'".s:get_visual_selection()."'".'"'."'".'"'."'' && read -p"
	"execute "term ++close qalc '".s:get_visual_selection()."'; read -p '' x"
	"call asyncrun#run("", "", "qalc '".s:get_visual_selection()."'")
endfun
fun! DoMathsToRegister(reg)
	let res = system("qalc -t '".s:get_visual_selection()."'|tr -d '\n'")
	call setreg(a:reg, res)
endfun
" }}}
" Format {{{
" Alignment {{{
fun! AlignWhitespaceFile(delim, aligner, splitregex)
	let file = getline(0, line("$"))
	let aligned = s:AlignWhitespaceLines(
				\ file, a:delim, a:aligner, a:splitregex)
	" This seems easier to do than a substitute or delete/put
	for i in range(len(aligned))
		call setline(i+1, aligned[i])
	endfor
endfun

fun! AlignWhitespaceVisual(delim, aligner, splitregex)
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let selection = split(s:get_visual_selection(), "\n")
	let aligned = s:AlignWhitespaceLines(selection, a:delim,
	                                   \ a:aligner, a:splitregex)
	" This seems easier to do than a substitute or delete/put
	for i in range(len(aligned))
		call setline(line_start + i, aligned[i])
	endfor
endfun

fun! s:AlignWhitespaceLines(lines, delim, aligner, splitregex)
	" Only align if there if there are tabs after non-whitespace
	" Don't expect this to also remove trailing whitespace
	" Fix | in regex
	let splitregex = substitute(a:splitregex, '|', '\\|', 'g')
	let aligned = a:lines
	let last = []
	let current_depth = 0
	let matches = [''] " dummy
	let testlist = range(len(a:lines))
	call map(testlist, '-1')
	while matches != testlist
		let last = aligned[:]
		" Find longest line and get matches for later
		let longest = -1
		let matches = []
		for line in aligned
			let m = match(line, '[^\t ]\zs\s*\%('.splitregex.'\)\s*[^\t ]',
						\ current_depth)
			" we'll need these later
			let matches = matches + [m]
			if m > longest
				let longest = m
			endif
		endfor
		" Set the depth for the next pass
		let current_depth = longest + 1
		" Apply alignment
		for i in range(len(aligned))
			let line = aligned[i]
			let matchstart = matches[i]
			let matchend = match(line,
					\ '[^\t ]\s*\%('.splitregex.'\)\s*\zs[^\t ]', matchstart-1)
			" Do nothing if there are no matches on the line
			if matchstart != -1 && matchend >= matchstart
				let newline = line[:matchstart-1]
						\ . repeat(a:aligner,longest - matchstart)
						\ . a:delim . line[matchend:]
				let aligned[i] = newline
			endif
		endfor
	endwhile
	return aligned
endfun

" }}}
" Indent {{{
fun! IndentFile()
	let winview = winsaveview()
	silent :w
	call system("indent -nbad -bap -nbc -bbo -hnl -br -brs -c33 -cd33 -ncdb
	          \ -ce -ci4 -cli0 -d0 -di1 -nfc1 -i4 -ip0 -l80 -lp -npcs -nprs
	          \ -npsl -sai -saf -saw -ncs -nsc -sob -nfca -cp33 -nss -ts4 -il1
	          \ . expand('%:t'))
	:e
	" Make templates work properly
	if &filetype == 'cpp'
		" Fuck this there are too many edge cases
		silent! :%s/\v ?\< ?([^\<\>]*[^\<\> ]) ?\> ?/<\1> /g
		silent! :%s/\v(\<[^\<\>]*[^\<\> ]*\>) ([\(\)\[\]\{\};])/\1\2/g
	endif
	silent :w
	call winrestview(winview)
endfun
command Indent call IndentFile()
" }}}
" Trim {{{
fun! TrimWhitespace()
	let l:line = line('.')
	let l:save = winsaveview()
	keeppatterns %s/\s\+$//eg
	call winrestview(l:save)
	echo l:line
	execute ':'.l:line
endfun
" }}}
" Email {{{
fun! FormatEmailRead()
	" Yeah, I am big brain
	set textwidth=78
	silent g/\v^%(Cc|Bcc|Reply-To):\s*$/d
	silent g/\v^(%(\> *)*)$\n\zs^\1.+$\ze\n^\1$/norm! gqj
	normal gg
endfun

fun! FormatEmailWrite()
	" Just accept it, my regex skills are glorious
	set textwidth=78
	let indent_specifier       = '%(\> *)*'
	let date_specifier         = '\n^'.indent_specifier.'On .*, .* wrote:\s*\n'
	let header_start_specifier = '^'.indent_specifier.'\s*[-_]+.*\n'
	" Don't want to join intentionally split things, for now I will assume
	" anything >60 chars can be split
	let g:paragraph_specifier  =
		\ '\v^('.indent_specifier.')\s*$\n%('.header_start_specifier.')@!'
		\.'\zs%(^\1\s*[^>].{60,}$\ze\n)+%(^\1\s*[^>].*$\ze\n)%(^\1\s*$)+'
	"let g:paragraph_specifier =
		"\ '\v^('.indent_specifier.')\s*$\n%('.header_start_specifier.')@!'
		"\.'\zs%(^\1[^>]\s*[^\t ].*$\ze\n){2,}%(^\1\s*$)+'
		"\.'%('.date_specifier.'|'.header_start_specifier.'|%$)@!'
	while search(g:paragraph_specifier) != 0
		execute 's/\v^'.indent_specifier.'\s*[^ ].*\zs\n^'.indent_specifier.'/ /'
	endwhile
endfun

augroup EmailFormatting
	autocmd! BufWritePre *.eml            call FormatEmailWrite()
	autocmd! BufReadPost *.eml            call FormatEmailRead()
	autocmd! BufWritePre /tmp/mutt*       call FormatEmailWrite()
	autocmd! BufReadPost /tmp/mutt*       call FormatEmailRead()
	autocmd! BufWritePre /tmp/neomutt*    call FormatEmailWrite()
	autocmd! BufReadPost /tmp/neomutt*    call FormatEmailRead()
augroup END
" }}}
" }}}
" Clipboard {{{
nnoremap <leader>pa ggdG"+p
nnoremap <leader>pi ggdG"+p:Indent<CR>
nnoremap <leader>ya gg"+yG
" }}}
" mdpytex {{{
" Jupyter {{{
fun! JupyterVimStart()
	term ++close ++hidden jupyter console
	call jupyter#load#MakeStandardCommands()
	let b:jupyter_kernel_type = 'python'
	JupyterConnect
	sleep 2 " You didn't see this
	call jupyter#SendCode(
		\ "import sys; sys.stdout=open('.jupyter_out','w'); "
		\."sys.stderr=open('.jupyter_err','w')"
	\)
endfun

fun! JupyterExit()
	call system("pkill -9 jupyter")
endfun

fun! JupyterRunCellIntoMarkdown()
	" Check we're in a python cell
	if !((search('^```','bWcn') == search('^```python$','bWcn')
			\ && (search('^```','bWcn') != 0)))
		echo "Not in a python cell"
		return
	endif

	" Clear last output
	call system('rm .jupyter_out; echo "" > .jupyter_out')
	call system('rm .jupyter_err; echo "" > .jupyter_err')
	call jupyter#SendCode('sys.stdout = open(".jupyter_out","a")')
	call jupyter#SendCode('sys.stderr = open(".jupyter_err","a")')

	call jupyter#SendCell()
	call jupyter#SendCode(
				\ "print('----------output end----------',flush=True)\n")

	" Go to end of cell
	if search('^```$','Wc') == 0
		echo "No closing cell delimiter"
		return 1
	endif

	if search('```output','Wn') == line('.') + 1
		" Remove existing output
		norm! j
		s/```output\n\%(\%(```\)\@!.*\n\)*```\n//
		norm! k
	endif

	" Put output in new block
	while readfile('.jupyter_out')[-1] != "----------output end----------"
		sleep 10m
		" Have we encountered an error? This isn't working yet
		if match(readfile('.jupyter_err')[-1], '^[^ ]*Error: ') != -1
			break
		endif
	endwhile

	" Don't pollute with lots of empty output blocks
	if readfile('.jupyter_out')[1:-2] != []
		call append(line('.'), ['```output','```'])
		call append(line('.')+1,readfile('.jupyter_out')[1:-2])
	endif
endfun

fun! JupyterRunAllIntoMarkdown()
	norm gg
	while search('^```python', 'cW') != 0
		if JupyterRunCellIntoMarkdown() == 1
			return 1
		endif
	endwhile
endfun

let b:jupyter_kernel_type = 'python'
let g:jupyter_cell_separators = ['```py','```']
let g:markdown_fenced_languages = ['python']
augroup pymd
	autocmd!
	autocmd VimLeave *.ipynb,*.md call JupyterExit()
	autocmd BufEnter *.ipynb,*.md call jupyter#load#MakeStandardCommands()
	autocmd BufEnter *.ipynb set filetype=markdown.python
augroup END
" }}}
" Pandoc {{{
fun! PandocMake()
	execute ':AsyncRun sh -c '."'".'(pandoc '
		\ . ' --defaults ~/.config/pandoc/pandoc.yaml '
		\ . expand('%:t:r').'.md -o '.expand('%:t:r').'.pdf '
		\ . '-V geometry:margin=1in '
		\ . '-H ~/.config/pandoc/draculaheader.tex '
		\ . '-H ~/.config/pandoc/commonheader.tex '
		\ . '--highlight-style=/home/tim/.config/pandoc/dracula.theme '
		\ . '--pdf-engine=xelatex '.")'"
		"\ . '&& if ! pgrep zathura >/dev/null; then zathura '
		"\ . expand('%:t:r').'.pdf & fi)'."'"
endfun
" }}}
" Vimtex {{{
let g:tex_flavor = 'latex'
let g:vimtex_view_automatic = 0
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
" }}}
fun! MdpytexRestartAndMake()
	call JupyterExit()
	sleep 2
	call JupyterVimStart()
	call JupyterRunAllIntoMarkdown()
	call PandocMake()
endfun
" }}}
" YouCompleteMe {{{
au VimEnter * let g:ycm_semantic_triggers.tex=g:vimtex#re#youcompleteme
let g:ycm_filetype_blacklist={
	\ 'cpp': 1, 'notes': 1, 'unite': 1, 'tagbar': 1, 'pandoc': 1, 'qf': 1,
	\ 'vimwiki': 1, 'text': 1, 'infolog': 1, 'mail': 1
	\ }
" }}}
" Make {{{
let g:asyncrun_open=10
autocmd! BufWritePost $MYVIMRC nested source %
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
		call MdpytexRestartAndMake()
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
		call PandocMake()
	else
		:make
	endif
endfun
" }}}
" Airline {{{
let g:airline#extensions#whitespace#mixed_indent_algo = 2
" }}}
" Project Specific {{{
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
" Keyboard Mappings {{{
" General {{{
let mapleader = " "
let maplocalleader = " "
nnoremap <leader>v :edit ~/.vim/git/.vimrc<CR>
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
" Maths {{{
noremap <leader>xr :call DoMathsQuickfix()<CR>
noremap <leader>xx :call DoMathsToRegister(v:register)<CR>
noremap <leader>xs :call DoMathsSubstitute()<CR>
noremap <leader>xc :term ++close qalc<CR>
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
" Jupyter {{{
" Start
nnoremap <leader>jj :call JupyterVimStart()<CR>
nnoremap <leader>jq :call JupyterExit()<CR>

" Run
nnoremap <leader>jx :call JupyterRunCellIntoMarkdown()<CR>
nnoremap <leader>ja :call JupyterRunAllIntoMarkdown()<CR>
nnoremap <leader>je :JupyterSendRange<CR>

" goto cell
nnoremap <leader>jc /```py<CR>
nnoremap <leader>jC ?```py<CR>

" misc
nnoremap <leader>ju :JupyterUpdateShell<CR>
nnoremap <leader>jb :PythonSetBreak<CR>
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
nnoremap <leader>b :Buffers<CR>
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
