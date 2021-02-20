" See you in hell, Rubocop!

" I see this all the time in other plugins, and I'm getting inexplicable
" problems with this plugin being loaded twice so... here we are, don't know
" why this happens
if exists('g:NyaoSeeYouInHell') | finish | endif

let s:n                                    = g:NyaoFn
let g:NyaoSeeYouInHell                     = {}
let g:NyaoSeeYouInHell.rubocop_accumulator = []

function! s:RuboCopReposDefined()
  if exists('g:NyaoSeeYouInHell.rubocop_repos')
    return 1
  else
    echoerr 'g:NyaoSeeYouInHell.rubocop_repos was not set in your vimrc after loading nyaoseeyouinhell. Try adding it and reloading.'
    return 0
  end
endfu

let s:StringInRuboCopRepos = s:n.IfElse(
\   { _ -> s:RuboCopReposDefined() }
\ )(
\   { repo_name -> s:n.Flip( s:n.FindStrInAry )( g:NyaoSeeYouInHell.rubocop_repos )( repo_name ) }
\ )(
\   { _ -> 0 }
\ )

" " path -> bool
let s:SupportedRuboCopRepo = s:n.FoldCompose(
      \ [ s:StringInRuboCopRepos
      \ , s:n.Fst
      \ , s:n.Last(1)
      \ , s:n.Split('/')
      \ ])

let s:AddRubocopError         = { line -> add(g:NyaoSeeYouInHell.rubocop_accumulator, line ) }
let s:ClearRubocopAccumulator = { -> s:n.LetObj(g:NyaoSeeYouInHell)('rubocop_accumulator')([]) }

" if you just want highlighted line, not the symbol beside the line number... probably the case if you only use one kind of sign
" se signcolumn=no
hi RedText ctermbg=1 ctermfg=235 cterm=reverse guibg=#262626 guifg=#8787af gui=reverse
call s:n.SignDefine({ "text" : "=>", "texthl" : "RedText", "linehl" : "RedText" })('rubocopsign')

let s:RuboCopLineNrParse = s:n.C( s:n.Snd )( s:n.Split(':') )

" Behold, the worst possible way to program :)
let s:RuboCopSignPlace = { buf -> { line -> s:n.Sequence(
  \ [ s:n.LazyCall(s:n.SignPlace)([ 'rubocopsign', 'rubocop', 0, buf
                                \ , { 'lnum': s:RuboCopLineNrParse(line), 'priority': 10 }])
  \ , s:n.LFC([ s:AddRubocopError, s:n.Join(':'), s:n.Tail, s:n.Split(':'), line ])])}}

" match anything that looks like it starts with a filepath
let s:WhenErrorLine      = s:n.When( s:n.MatchStrBool('^\w*/.*:') )
let s:RuboCopSignUnplace = { -> s:n.SignUnplace( 'rubocop' )( {} ) }
let s:DevStyleHandler    = { buf -> { channel, msg -> s:WhenErrorLine( s:RuboCopSignPlace(buf) )( msg ) }}

let s:DevStyleCloseHandler = { channel ->
  \ s:n.Sequence([ s:n.PopupClear
               \ , { -> s:n.RubyPopupTL( g:NyaoSeeYouInHell.rubocop_accumulator )}])}

" should probably extract out the When logic here, as this is pretty hard
" to read
let g:NyaoSeeYouInHell.AsyncDevStyle = { buf ->
  \ s:n.When( s:SupportedRuboCopRepo )({ _ ->
    \ s:n.Sequence([ s:ClearRubocopAccumulator
                 \ , s:RuboCopSignUnplace
                 \ , s:n.LazyCall(s:n.SimpleJob)([ s:DevStyleCloseHandler
                                               \ , s:DevStyleHandler(buf)
                                               \ , 'bundle exec rubocop ' . buf ])])})( s:n.Cwd() )}

augroup nyaoseeyouinhell
  autocmd!
  au BufWritePost *.rb call g:NyaoSeeYouInHell.AsyncDevStyle(bufname())
augroup END
