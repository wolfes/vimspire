"=====================================================================
" File:        vimspire.vim
" Description: Connect vim with tabspire.
" Author:      Wolfe Styke <vimspire@gmail.com>
" Licence:     ???
" Website:     http://wolfes.github.com/vimspire/
" Version:     0.0.0
" Note:        Connect all the things!
"
" Original taglist copyright notice:
"              Permission is hereby granted to use and distribute this code,
"              with or without modifications, provided that this copyright
"              notice is copied with it. Like anything else that's free,
"              vimspire.vim is provided *as is* and comes with no warranty of
"              any kind, either expressed or implied. In no event will the
"              copyright holder be liable for any damamges resulting from the
"              use of this software.
" ====================================================================

scriptencoding utf-8

" Exit when your app has already been loaded (or "compatible" mode set)
if !exists("g:loaded_vimspire")
	" Set version number
	let g:loaded_vimspire = 3
	let s:keepcpo = &cpo
	set cpo&vim
else
    finish
endif

let s:default_opts = {
	\	'tabspire_client_id': '"PUT_YOUR_TABSPIRE_CLIENT_ID_HERE"',
	\	'vimspire_enabled': 1,
	\	'vimspire_map_keys': 1,
	\	'vimspire_cmdsync_host': '"http://cmdsync.com:3000/api/0/"',
	\	'vimspire_port': 3000,
	\	'vimspire_map_prefix': '"<Leader>"',
	\	'vimspire_auto_connect': 1
\}

for kv in items(s:default_opts)
	" Set global keys in defailt_ops to their value if key is unset.
	let k = 'g:'.kv[0]
	let v = kv[1]
	if !exists(k)
		exe 'let '.k.'='.v
	endif
endfor

python << EOF
import urllib, urllib2, vim
TABSPIRE_REQUEST_URL = (
	vim.eval('g:vimspire_cmdsync_host') +
	"tabspire/" +
	vim.eval('g:tabspire_client_id'))
EOF

" Unused, example of how to map commands to plugin-prefix.
" execute "nnoremap"  g:vimspire_map_prefix."d"  ":call <sid>vimspireDelete()<CR>"

" Features (Idea List)
"
" Reload tab:
" - by name.
" - Set default tab name to reload when
"    saving (performing 'save/waf' cmd) for this file.

function! SaveAndRebuild()
	wa
	" Replace with build templates script.
	" silent! exec "r!ping -c 1 www.google.com"
	" u
endfunction

function! OpenTabByName(name)
python << EOF
request_url = TABSPIRE_REQUEST_URL + '/openTabByName'

try:
	params = urllib.urlencode({
		'tabName' : vim.eval('a:name')
	})
	response = urllib2.urlopen(request_url, params)

except Exception, e:
    print e

EOF
endfunction

function! OpenGoogleSearch(query)
python << EOF
request_url = TABSPIRE_REQUEST_URL + '/openGoogleSearch'

try:
	params = urllib.urlencode({
		'query' : vim.eval('a:query')
	})
	response = urllib2.urlopen(request_url, params)
except Exception, e:
    print e
EOF
endfunction

function! OpenURL(url)
python << EOF
request_url = TABSPIRE_REQUEST_URL + '/openURL'

try:
	params = urllib.urlencode({
		'url' : vim.eval('a:url')
	})
	resp_loc = urllib2.urlopen(request_url, params)
except Exception, e:
    print e
EOF
endfunction


function! OpenSelectedURL()
" Sends req to Tabspire thru cmdSync
" to open the current buffer's selected line as a url.

python << EOF
request_url = TABSPIRE_REQUEST_URL + '/openURL'

try:
	params = urllib.urlencode({
		'url' : vim.current.line
	})
	resp_cmd = urllib2.urlopen(request_url, params)
except Exception, e:
    print e
EOF
endfunction


function! OpenPB() range
" Sends req to Tabspire thru cmdSync
" to open the current buffer's selected line as a url.

:'<,'> !pb

python << EOF
request_url = TABSPIRE_REQUEST_URL + '/openURL'

try:
	params = urllib.urlencode({
		'url' : vim.current.line
	})
	resp_cmd = urllib2.urlopen(request_url, params)
except Exception, e:
    print e
EOF
" Undo pastebin insertion of url.
:	normal! u
endfunction


function! ReloadTabByName(tabName)
" Reload a tab by its name in Tabspire.

python << EOF
request_url = TABSPIRE_REQUEST_URL + '/reloadTabByName'

try:
	params = urllib.urlencode({
		'tabName' : vim.eval('a:tabName')
	})
	resp_cmd = urllib2.urlopen(request_url, params)
except Exception, e:
    print e
EOF
endfunction

function! ReloadCurrentTab()
" Reload currently focused tab in Chrome.

python << EOF
request_url = TABSPIRE_REQUEST_URL + '/reloadCurrentTab'

try:
	params = urllib.urlencode({})
	resp_cmd = urllib2.urlopen(request_url, params)
except Exception, e:
    print e
EOF
endfunction

function! ReloadFocusMark(markChar)
" Reload/Open and Focus marked tab in Chrome.

python << EOF
request_url = TABSPIRE_REQUEST_URL + '/reloadFocusMark'

try:
	params = urllib.urlencode({
		'markChar': vim.eval('a:markChar')
	})
	resp_cmd = urllib2.urlopen(request_url, params)
except Exception, e:
    print e
EOF
endfunction

" Create command OpenTabByName: exactly 1 tabname.
command! -nargs=1 OpenTabByName call OpenTabByName ( '<args>' )

" Create command ReloadCurrentTab: exactly 0 args.
command! -nargs=0 ReloadCurrentTab call ReloadCurrentTab()

" Create command ReloadFocusMark: exactly 1 args.
command! -nargs=1 ReloadFocusMark call ReloadFocusMark ( '<args>' )

" Create command ReloadTabByName: exactly 1 tabname.
command! -nargs=1 ReloadTabByName call ReloadTabByName ( '<args>' )

" Create command OpenGoogleSearch: 1+ search terms.
command! -nargs=+ OpenGoogleSearch call OpenGoogleSearch ( '<args>' )

" Create command OpenURL: exactly 1 url.
command! -nargs=1 OpenURL call OpenURL ( '<args>' )

" Create command OpenSelectedURL: no args.
command! -nargs=0 OpenSelectedURL call OpenSelectedURL ( )

" Create command OpenPB: no args.
command! -range OpenPB call OpenPB ( )

if g:vimspire_map_keys
	noremap <Leader>m :OpenTabByName 
	noremap <Leader>M :ReloadTabByName 
	noremap <Leader>j :ReloadFocusMark 
	noremap <Leader>R :ReloadCurrentTab<CR>
	noremap <Leader>k :OpenGoogleSearch 
	noremap <Leader>u :OpenURL 
	noremap <Leader>U :OpenSelectedURL<CR>
	vnoremap <Leader>p :call OpenPB()<CR>
	"vnoremap <Leader>p :OpenPB()<CR>
endif


" ====================================================================
let &cpo= s:keepcpo
unlet s:keepcpo
