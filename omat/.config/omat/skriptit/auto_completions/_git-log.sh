#compdef git-log.sh

function _anna_git_haarat() {
    ## Tällaisella loitsulla zsh:ssä otetaan taulukko joka katkaistu \n kohdalta:
    IFS=$'\n' haarat=( $(git branch --format="%(refname:short)") )
    haarat+=( "--all" "--show-current" )

    _describe -t output 'gitin haarat' haarat
}

viewModet='( 1\:"väljä ja selkeä tyyli (default)"  2\:"selkeä yksirivinen tyyli" 3\:"vanha yksirivinen tyyli, joka näyttää kaikki \"ref\":it" )'

_arguments -s \
    '1:haarat:_anna_git_haarat' \
    "2:mode:($viewModet)" \
