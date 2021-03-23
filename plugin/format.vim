com! Act80char nnoremap i gk|nnoremap e gj|set columns=86|set wrap|set linebreak
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
	call system("indent -nbad -bap -nbc -bbo -hnl -br -brs -c33 -cd33 -ncdb "
	          \."-ce -ci4 -cli0 -d0 -di1 -nfc1 -i4 -ip0 -l80 -lp -npcs -nprs "
	          \."-npsl -sai -saf -saw -ncs -nsc -sob -nfca -cp33 -nss -ts4 -il1 "
	          \.expand('%:t'))
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
command! Indent call IndentFile()
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
