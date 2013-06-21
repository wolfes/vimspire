"=====================================================================
" File:        vimspire.vim
" Description: Connect vim with tabspire.
" Author:      Wolfe Styke <vimspire@gmail.com>
" Licence:     ???
" Website:     http://wolfes.github.com/vimspire/
" Version:     0.0.0
" Note:        Connect all the things!
"
" Setup:
"	Add to your .vimrc:
"		g:tabspire_client_id="your_client_id"
"	Optioanl, use if you want to map your own bindings.
"		g:vimspire_map_keys=0
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
	\	'tabspire_client_id': '"CLIENT_ID"',
	\	'vimspire_enabled': 1,
	\	'vimspire_map_keys': 1,
	\	'vimspire_local_host': '"http://localhost:3000/tabspire/api/0/"',
	\	'vimspire_cmdsync_host': '"http://cmdsync.com:3000/tabspire/api/0/"',
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

" Initialize Python Server URL Constants.
python << EOF
import urllib, urllib2, vim, subprocess
REMOTE_TABSPIRE_REQUEST_URL = vim.eval('g:vimspire_cmdsync_host')
LOCAL_TABSPIRE_REQUEST_URL = vim.eval('g:vimspire_local_host')

TABSPIRE_CLIENT_ID = vim.eval('g:tabspire_client_id')

#TABSPIRE_REQUEST_URL = LOCAL_TABSPIRE_REQUEST_URL
TABSPIRE_REQUEST_URL = REMOTE_TABSPIRE_REQUEST_URL

TABSPIRE_GROUP = ''
REDIR_TO_GROUP = False

def postCmdToPrivate(params, method):
    """Post command to a group.

        Args:
            method: String of requested method, ie: '/openTabByName'.
    """
    if REDIR_TO_GROUP:
        return postCmdToGroup(params, method)
    params['channel-type'] = 'private'
    request_url = TABSPIRE_REQUEST_URL + TABSPIRE_CLIENT_ID + method
    return postCmd(params, request_url)

def postCmdToGroup(params, method):
    """Post command to a group.

        Args:
            method: String of requested method, ie: '/openTabByName'.
    """
    params['channel-type'] = 'group'
    request_url = TABSPIRE_REQUEST_URL + TABSPIRE_GROUP + method
    return postCmd(params, request_url)

def postCmd(params, request_url):
    """Post request with params to nspire server.

    Request url looks like:
        http://{hostname}/tabspire/api/0/channel-name/requested-method

    Args:
        params: Dictionary of request params.
            Key: 'channel-type' in ['group', 'private'] specifies target type.
            Other keys transparently passed through to client.
    """
    params = urllib.urlencode(params);
    headers = {"Content-type": "application/x-www-form-urlencoded"}
    req = urllib2.Request(request_url, params, headers)
    try:
        response = urllib2.urlopen(req)
        return response
    except Exception, e:
        print e
    return {}
EOF

function! SelectServer(index)
python << EOF
"""Select which cmdsync server to use."""
index = vim.eval('a:index');
if index == '0':
	TABSPIRE_REQUEST_URL = REMOTE_TABSPIRE_REQUEST_URL
elif index == '1':
	TABSPIRE_REQUEST_URL = LOCAL_TABSPIRE_REQUEST_URL
EOF
endfunction

function! SelectGroup(group_name)
python << EOF
TABSPIRE_GROUP = vim.eval('a:group_name')
REDIR_TO_GROUP = True
EOF
endfunction

function! SelectPrivate()
python << EOF
REDIR_TO_GROUP = False
EOF
endfunction

" Features (Idea List)
" - Set default tab name to reload when
"   saving (performing 'save/waf' cmd) for this file.

function! SaveAndRebuild()
	wa
	" Replace with build templates script.
	" silent! exec "r!ping -c 1 www.google.com"
	" u
endfunction

function! OpenTabByName(name)
python << EOF
resp = postCmdToPrivate({'tabName' : vim.eval('a:name')}, '/openTabByName')
EOF
endfunction

function! OpenGoogleSearch(query)
python << EOF
resp = postCmdToPrivate({'query' : vim.eval('a:query')}, '/openGoogleSearch')
EOF
endfunction

function! OpenURL(url)
python << EOF
resp = postCmdToPrivate({'url' : vim.eval('a:url')}, '/openURL')
EOF
endfunction

function! OpenSelectedURL()
" Open cWORD in Chrome Tab, through cmdSync->Tabspire.
python << EOF
resp = postCmdToPrivate({'url' : vim.eval('expand(\'<cWORD>\')')}, '/openURL')
EOF
endfunction

function! OpenPB() range
" Sends req to Tabspire thru cmdSync
" to open the current buffer's selected line as a url.
:'<,'> !pb
python << EOF
resp = postCmdToPrivate({'url' : vim.current.line}, '/openURL')
EOF
" Undo pastebin insertion of url.
:	normal! u
endfunction

function! ReloadTabByName(tabName)
" Reload a tab by its name in Tabspire.
python << EOF
resp = postCmdToPrivate({'tabName' : vim.eval('a:tabName')}, '/reloadTabByName')
EOF
endfunction

function! ReloadCurrentTab()
" Reload currently focused tab in Chrome.
python << EOF
resp = postCmdToPrivate({}, '/reloadCurrentTab')
EOF
endfunction

function! FocusNextTab()
" Focus tab before currently focused tab in Chrome.
python << EOF
resp = postCmdToPrivate({}, '/focusNextTab')
EOF
endfunction

function! FocusPrevTab()
" Focus tab after currently focused tab in Chrome.
python << EOF
resp = postCmdToPrivate({}, '/focusPrevTab')
EOF
endfunction

function! FocusMark(markChar)
" Focus/Open marked tab in Chrome.
python << EOF
resp = postCmdToPrivate({'markChar' : vim.eval('a:markChar')}, '/focusMark')
EOF
endfunction

function! FocusCurrentWindow()
" Focus Chrome's 'focused tab', giving focus to Chrome App.
python << EOF
resp = postCmdToPrivate({'foo':'bar'}, '/focusCurrentWindow')
EOF
endfunction

function! ReloadFocusMark(markChar)
" Reload/Open and Focus marked tab in Chrome.
python << EOF
resp = postCmdToPrivate({'markChar' : vim.eval('a:markChar')}, '/reloadFocusMark')
EOF
endfunction


" Select remote=0 or local=1 server to message.
command! -nargs=1 SelectServer call SelectServer ( '<args>' )

" Select group name for server to message.
command! -nargs=1 SelectGroup call SelectGroup ( '<args>' )

" Select to use CLIENT_ID for server to message.
command! -nargs=0 SelectPrivate call SelectPrivate()

" Create command OpenTabByName: exactly 1 tabname.
command! -nargs=1 OpenTabByName call OpenTabByName ( '<args>' )

" Create command ReloadCurrentTab: exactly 0 args.
command! -nargs=0 ReloadCurrentTab call ReloadCurrentTab()

" Create command ReloadFocusMark: exactly 1 args.
command! -nargs=1 ReloadFocusMark call ReloadFocusMark ( '<args>' )

" Create command FocusMark: exactly 1 args.
command! -nargs=1 FocusMark call FocusMark ( '<args>' )

" Create command FocusCurrentWindow: exactly 0 args.
command! -nargs=0 FocusCurrentWindow call FocusCurrentWindow()

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

" Create command ReloadCurrentTab: exactly 0 args.
command! -nargs=0 FocusNextTab call FocusNextTab()
"
" Create command ReloadCurrentTab: exactly 0 args.
command! -nargs=0 FocusPrevTab call FocusPrevTab()

if g:vimspire_map_keys
    noremap <Leader>vs :SelectServer 
    noremap <Leader>vg :SelectGroup 
    noremap <Leader>vp :SelectPrivate<CR>

    noremap <Leader>m :OpenTabByName 
	noremap <Leader>M :ReloadTabByName 
	noremap <Leader>j :ReloadFocusMark 
	noremap <Leader>J :FocusMark 
	noremap <Leader>R :ReloadCurrentTab<CR>
	noremap <Leader>k :OpenGoogleSearch 
	noremap <Leader>u :OpenURL 
	noremap <Leader>U :OpenSelectedURL<CR>
	vnoremap <Leader>p :call OpenPB()<CR>
	"vnoremap <Leader>p :OpenPB()<CR>
	noremap <Leader>x :FocusCurrentWindow<CR>
    noremap <Leader>z :FocusPrevTab<CR>
    noremap <Leader>c :FocusNextTab<CR>
endif


" ====================================================================
let &cpo= s:keepcpo
unlet s:keepcpo
