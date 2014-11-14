
if &cp || exists('g:loaded_projtags')
  finish
endif

let g:loaded_projtags = 1

if v:version < 700
  echohl WarningMsg
  echomsg 'ProjTags: Vim version is too old, ProjTags requires at least 7.0'
  echohl None
  finish
endif

if !exists('g:projtags_bin')
 let g:projtags_bin = "ctags"
endif

if !executable(g:projtags_bin)
  echohl WarningMsg
  echomsg 'ProjTags: could not fin ctags binary "' . g:projtags_bin . '"'
  echohl None
  finish
endif

if !exists('g:projtags_path')
  let g:projtags_path = expand("~/.tags")
endif

if !isdirectory(g:projtags_path)
  call mkdir(g:projtags_path, "p")
endif

let s:projtags_list = {}

function! s:getTagName(path)
  return substitute(substitute(a:path, '/', '', ''), '/', '-', 'g')
endfunction

function! s:getTagFileName(path)
  return g:projtags_path . '/' . s:getTagName(a:path) . '.tags'
endfunction

" Returns the list of source paths associated with project a:name
function! s:getSourcePaths(name)
  if !has_key(s:projtags_list, a:name)
    let s:projtags_list[a:name] = []
  endif
  return s:projtags_list[a:name]
endfunction

function! projtags#add(name, path)
  let l:list = s:getSourcePaths(a:name)
  let l:path = expand(a:path)
  if isdirectory(l:path)
    call add(l:list, l:path)
    echomsg 'ProjTags: source path "' . l:path . '" added'
  else
    echohl WarningMsg
    echomsg 'ProjTags: source path "' . l:path . '" does not exists. Skipping'
    echohl None
  endif
endfunction

function! projtags#get(name)
  return s:getSourcePaths(a:name)
endfunction

" Generates the tags file for project a:name. Note that depending on the number
" of sources this command may take a long time to finish.
function! projtags#gen(name)
  let l:list = s:getSourcePaths(a:name)
  if empty(l:list)
    echohl WarningMsg
    echomsg 'ProjTags: project "' . a:name . '" has no sources.'
    echohl None
    return
  endif
  echomsg 'ProjTags: generating tags for "' . a:name '", please wait...'
  for i in l:list
    let l:cmd = g:projtags_bin . ' -R -f ' . s:getTagFileName(i) . ' --c++-kinds=+p --fields=+iaS --extra=+q ' . i
    call system(l:cmd)
  endfor
  redraw
  echomsg 'ProjTags: generating tags for "' . a:name '" finished.'
endfunction

" Loads the tags for project a:name into the &tags variable. This function is
" indeponent and only tags that are not alreay in the &tags are added.
function! projtags#load(name)
  let l:list = s:getSourcePaths(a:name)
  if empty(l:list)
    echohl WarningMsg
    echomsg 'ProjTags: project "' . a:name . '" has no sources.'
    echohl None
    return
  endif

  let l:taglist = split(&tags, ',')

  for i in l:list
    let l:tagfile = s:getTagFileName(i)
    if index(l:taglist, l:tagfile) < 0
      call add(l:taglist, l:tagfile)
    endif
  endfor

  let &tags = join(l:taglist, ',')

  echomsg 'ProjTags: loaded tags for "' . a:name
endfunction

" Removes the tags fro project a:name from the &tags variable
function! projtags#unload(name)

  let l:list = s:getSourcePaths(a:name)

  if empty(l:list)
    echohl WarningMsg
    echomsg 'ProjTags: project "' . a:name . '" has no sources.'
    echohl None
    return
  endif

  let l:taglist = map(copy(l:list), 's:getTagFileName(v:val)')
  let l:currlist = split(copy(&tags), ',')
  let l:newlist = []

  for i in l:currlist
    if index(l:taglist, i) < 0
      call add(l:newlist, i)
    endif
  endfor

  let &tags = join(l:newlist, ',')
  echomsg 'ProjTags: unloaded tags for "' . a:name
endfunction

command! -nargs=* ProjTagsAdd call projtags#add(<f-args>)
command! -nargs=1 ProjTagsGen call projtags#gen(<f-args>)
command! -nargs=1 ProjTagsLoad call projtags#load(<f-args>)
command! -nargs=1 ProjTagsUnload call projtags#unload(<f-args>)
