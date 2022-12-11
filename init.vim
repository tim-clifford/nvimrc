" Plugins {{{
call plug#begin('~/.config/nvim/plugged')

" General stuff
Plug 'dracula/vim', { 'name': 'dracula' }
Plug 'skywind3000/asyncrun.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'vim-airline/vim-airline'
Plug 'puremourning/vimspector'
Plug 'junegunn/vim-emoji'
Plug 'vim-scripts/vis'

" Neovim stuff
Plug 'neovim/nvim-lspconfig'
Plug 'tjdevries/nlua.nvim'
"Plug 'nvim-lua/lsp_extensions.nvim' " Some problems with get_count
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" Completion
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'

" Git
Plug 'tpope/vim-fugitive'

" GitHub
Plug 'pwntester/octo.nvim'
Plug 'kyazdani42/nvim-web-devicons'

" Snippets
Plug 'sirver/ultisnips'
Plug 'honza/vim-snippets'

" Functionality
Plug 'lervag/vimtex'
Plug 'tim-clifford/vim-venus'
Plug 'tim-clifford/vim-qalc'
Plug 'tim-clifford/vim-dirdiff'
Plug 'dhruvasagar/vim-table-mode'
Plug 'thinca/vim-ref'
Plug 'ujihisa/ref-hoogle'
Plug 'dbeniamine/vim-mail'
Plug 'ellisonleao/glow.nvim'
Plug 'ThePrimeagen/harpoon'
Plug 'adelarsq/vim-matchit'

Plug 'mattn/webapi-vim'
Plug 'kana/vim-metarw'
Plug 'tim-clifford/vim-metarw-gdrive'

" Syntax
Plug 'chikamichi/mediawiki.vim'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'dag/vim-fish'
Plug 'ap/vim-css-color'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'powerman/vim-plugin-AnsiEsc'
Plug 'tkztmk/vim-vala'

" External
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

call plug#end()
" }}}
" General {{{

" Enable local configs
set exrc
set secure " disallow :autocmd, shell, and write commands in local config

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
let g:python_recommended_style = 0 " Fuck PEP who tf made this default

if system("echo $SHLVL") == 1
	cabbrev q <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'close' : 'q')<CR>
	cabbrev wq <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'w\|close' : 'q')<CR>
	cabbrev qa <c-r>=('call DontExit()')<CR>
	cabbrev wqa <c-r>=('call DontExit()')<CR>
	cabbrev x <c-r>=('call DontExit()')<CR>
	cabbrev xa <c-r>=('call DontExit()')<CR>
endif

fun! DontExit()
	echom "You opened me with exec. You probably don't want to do that."
endfun

" Visual
set incsearch nohlsearch
set foldmethod=marker
set noshowmode
set nowrap
set number
set guicursor=
set list

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
set nrformats+=alpha

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
	execute 'AsyncRun -mode=terminal curl cht.sh/'.argsl[0].'/'.join(argsl[1:], '+')
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
"
fun! ExecInTerm1(cmd)
	lua require("harpoon.term").gotoTerminal(1)
	exec "norm! A" . "" . a:cmd . "\n"
endfun

let g:asyncrun_open=5
autocmd! BufWritePost $MYVIMRC nested source %
execute 'autocmd! BufWritePost '.$HOME.'/.vim/git/.vimrc-nvim nested source %'
fun! MakeAndRun()
	if filereadable('start.sh')
		"lua require("harpoon.term").gotoTerminal(1)
		:AsyncStop
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		:AsyncRun ./start.sh
	elseif filereadable('Makefile')
		:AsyncRun make
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		if filereadable(expand('%:r'))
			call system('./'.expand('%:r').'>stdout.txt 2>stderr.txt&')
		endif
	elseif &filetype == 'python'
		:AsyncStop
		execute ':AsyncRun python3 '.expand('%')
	elseif &filetype == 'sh'
		:AsyncStop
		execute ':AsyncRun ./'.expand('%')
	elseif &filetype == 'venus'
		:AsyncStop
		call venus#Make()
	elseif &filetype == 'tex'
		execute ':AsyncRun pdflatex '.expand('%')
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		call venus#OpenZathura()
	else
		echom "I don't know how to make this"
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
" Filetype {{{
autocmd FileType verilog set ts=8
" }}}
" Network stuff {{{
command! -nargs=1 Curl :r !curl <q-args> 2>/dev/null
command! -nargs=1 Gurl :r !gmni gemini://<q-args> -j once
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
fun! BlogInit(title) abort
	let name = join(split(system("echo -n '".
					\ substitute(tolower(a:title), "'", "", "g")
					\."' | tr -d '[:punct:]'")
				\, ' '), '-')

	cd ~/projects/tim.clifford.lol
	exe "silent !mkdir -p blog/".name
	let fname = 'blog/'.name.'/index.md'

	" exec "lua require('harpoon.term').sendCommand(1, 'firefox localhost:3000/blog/".name." & npm run dev\\n')"

	if ! filereadable(fname)
		" This is a bit awkward unfortunately
		execute 'edit ' . fname
		let header = [
					\ '---',
					\ 'title: "'.a:title.'"',
					\ 'excerpt: ""',
					\ 'createdAt: "'.system("date +'%Y-%m-%d' | tr -d '\n'").'"',
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
fun! BlogGeminiInit() abort
	"" sanity checks
	if match(expand("%:p"), "tim\.clifford\.lol/blog/.*\.md") == -1
		echom "Start from markdown"
		return 1
	endif
	!$(dirname %)/../../scripts/build.sh --blog

	let g:blizpath = substitute(
				\ substitute(expand("%:p"), ".md$", ".bliz", ""),
				\ "blog/", "bliz/blog/", "")
	execute ":e " . g:blizpath
endfun
"fun! BlogPlainInit() abort
	"" sanity checks
	"if match(expand("%:p"), "tim\.clifford\.lol/blog/.*\.bliz") == -1
		"echom "Start with the gemini version"
		"return 1
	"endif
	"if filereadable(substitute(expand("%:p"), ".bliz$", ".txt", ""))
		"echom "Will not overwrite file"
		"return 1
	"endif
	"exe ":!cp " . expand("%:p") . " " . substitute(expand("%:p"), ".bliz$", ".txt", "")
	"exe ":e " . substitute(expand("%:p"), ".bliz$", ".txt", "")
	":%s/=> \([^ ]*\) \(.*\)/\2: \1/
"endfun
"fun! BlogPublish() abort
	"" sanity checks
	"if match(expand("%:p"), "tim\.clifford\.lol/blog/.*\.md") == -1
		"echom "Not a valid path"
		"return 1
	"endif
	"let blizpath = substitute(expand("%:p"), ".md$", ".bliz", "")
	"if ! filereadable(blizpath)
		"echom "No gemini version exists"
	"endif
	"execute "!scp " . blizpath . " pip:bliz/serve/blog/"
	"!npm run all
	""execute '!'.substitute(expand('%:p'), 'blog\/[^/]*\.md$',
				""\ 'scripts\/sendmail.sh ', '') . expand('%')
"endfun
"fun! BlogEmailTest() abort
	"" sanity checks
	"if match(expand("%:p"), "tim\.clifford\.lol/blog/.*\.md") == -1
		"echom "Not a valid path"
		"return 1
	"endif
	"execute '!'.substitute(expand('%:p'), 'blog\/[^/]*\.md$',
				"\ 'scripts\/sendmail.sh ', '') . expand('%') . ' --test'
"endfun
"fun! WebInit()
	"cd ~/projects/https-tim.clifford.lol
	"lua require('harpoon.term').sendCommand(1, 'firefox localhost:3000 & npm run dev\n')
	"edit pages/index.js
"endfun
"fun! WebPublishAndCommit()
	"AsyncRun npm run all
	"Git
"endfun
command! -nargs=+ Blog :call BlogInit(<q-args>)
command! BlogGemini :call BlogGeminiInit()
command! BlogPlain :call BlogPlainInit()
"command! BlogEmailTest :call BlogEmailTest()
"command! BlogPublish :call BlogPublish()
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
let g:pandoc_options         = '--citeproc'
let g:venus_pandoc_callback  = ['venus#OpenZathura']
let g:venus_ignorelist       = ['README.md', 'https-tim.clifford.lol/blog']
" }}}
" Airline {{{
let g:airline_extensions = ['quickfix', 'netrw', 'term', 'csv', 'branch', 'fugitiveline', 'nvimlsp', 'po', 'wordcount', 'searchcount']
let g:airline#extensions#wordcount#filetypes = '\vasciidoc|help|mail|markdown|markdown.pandoc|org|rst|tex|text|venus'
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
" Completion {{{
set completeopt=menu,menuone,noselect

lua <<EOF
  -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    mapping = {
      ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
      ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
      ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
      ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
      ['<C-n>'] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      }),
      ['<C-e>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      -- { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
EOF

" }}}
" Lspconfig {{{
lua require('lspconfig').pyright.setup{capabilities = capabilities}
lua require('lspconfig').bashls.setup{capabilities = capabilities}
lua require('lspconfig').tsserver.setup{capabilities = capabilities}
lua require('lspconfig').vimls.setup{capabilities = capabilities}
lua require('lspconfig').clangd.setup{capabilities = capabilities}
lua require('lspconfig').csharp_ls.setup{capabilities = capabilities}
lua require('lspconfig').hls.setup{capabilities = capabilities}
"lua require('lspconfig').ghdl_ls.setup{capabilities = capabilities}
lua require('lspconfig').sumneko_lua.setup{capabilities = capabilities}
lua require('lspconfig').phpactor.setup{capabilities = capabilities}
"lua require('lspconfig').ltex.setup{}
"lua require('lspconfig').fortls.setup{capabilities = capabilities}
" }}}
" Telescope {{{
lua require('telescope').load_extension('octo')
" }}}
" Ref {{{
command! -nargs=+ Rpy :Ref pydoc <args>
command! -nargs=+ Rnp :Ref pydoc numpy.<args>
command! -nargs=+ Rplt :Ref pydoc matplotlib.pyplot.<args>
command! -nargs=+ Rhs :Ref hoogle <args>
" }}}
" Mail {{{
let g:VimMailContactsProvider=['khard']
let g:VimMailSpellLangs=['en']
let g:VimMailDoNotMap=1

fun! s:mailCompleteMaybe()

	" Check we are in a valid line
	if match(getline("."), 'To:\|Cc:\|Bcc:') == 0
		let cursorpos = getpos(".")
		call cursor(0, cursorpos[2] - 1) " move cursorpos back 1 (onto word)
		if strlen(expand('<cword>')) > 1
			return "\<C-x>\<C-o>"
		endif
	endif
endfun

augroup MailCompletion
	autocmd!
	autocmd FileType mail inoremap <expr> <Tab> <SID>mailCompleteMaybe()
augroup END
" }}}
" Glow {{{
let g:glow_border="rounded"
let g:glow_width=80
" }}}
" }}}
" Keyboard Mappings {{{
" General {{{
let mapleader = " "
let maplocalleader = " "
nnoremap <silent> <leader>v<leader> :edit ~/.config/nvim/init.vim<CR>
" Why is this not default, I don't get it
noremap Y y$
noremap <silent> <leader>j :next<CR>
noremap <silent> <leader>J :prev<CR>

noremap n h
noremap e j
noremap i k
noremap o l
noremap k o
noremap l e
noremap h i
noremap j n

noremap N H
noremap E J
noremap I K
noremap O L
noremap K O
noremap L E
noremap H I
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
"noremap <leader>u :%s/’/'/ge|%s/“/"/ge|%s/”/"/ge|%s/…/.../ge<CR>
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
tnoremap <c-w> <C-\><C-n>
"tnoremap <Esc> <C-\><C-n>
"tnoremap <Esc><Esc> <C-\><C-n>
"set timeout timeoutlen=1000  " Default
"set ttimeout ttimeoutlen=100  " Set by defaults.vim
"noremap <Leader>tt :call termopen('zsh')<CR>
"noremap <Leader>ts :term<CR>
"noremap <Leader>tv :vertical term<CR>
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
nnoremap gd :lua  vim.lsp.buf.definition()<CR>
nnoremap gi :lua  vim.lsp.buf.implementation()<CR>
nnoremap gs :lua  vim.lsp.buf.signature_help()<CR>
nnoremap gr :lua  vim.lsp.buf.rename()<CR>
nnoremap gl :call LSP_open_loclist()<CR>
nnoremap gn :lua  vim.lsp.diagnostic.goto_next()<CR>
nnoremap gj :lua  vim.lsp.buf.references()<CR>
nnoremap gt :lua  vim.lsp.buf.type_definition()<CR>

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
"inoremap : :<C-X><C-U>
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
noremap <leader>g :Git<CR>
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
" Mail {{{
nnoremap <LocalLeader>a :call vimmail#spelllang#SwitchSpellLangs()<CR>
" }}}
" Harpoon {{{
nnoremap <silent> <leader>m :lua require("harpoon.mark").add_file()<CR>
nnoremap <silent> <leader>! :lua require("harpoon.term").gotoTerminal(1)<CR>
nnoremap <silent> <leader>£ :lua require("harpoon.term").gotoTerminal(2)<CR>
nnoremap <silent> <leader>% :lua require("harpoon.term").gotoTerminal(3)<CR>
nnoremap <silent> <leader>& :lua require("harpoon.term").gotoTerminal(4)<CR>
" }}}
" }}}
" }}}
