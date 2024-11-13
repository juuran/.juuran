#compdef git-log.sh

function _anna_git_haarat() {
    ## Tällaisella loitsulla zsh:ssä otetaan taulukko joka katkaistu \n kohdalta:
    IFS=$'\n' haarat=( $(git branch --format="%(refname:short)") )
    haarat+=( "--all" "--show-current" )

    _describe -t output 'gitin haarat' haarat
}

viewModet='( 1\:"väljä ja selkeä tyyli (oletus, topologian mukaan)" 2\:"väljä ja selkeä tyyli (ajan mukaan)"  3\:"selkeä yksirivinen tyyli (topologian mukaan)" 4\:"selkeä yksirivinen tyyli (ajan mukaan)" 5\:"legacy yksirivinen tyyli, joka näyttää \"ref\":it lyhentämättöminä" )'

_arguments -s \
    '1:haarat:_anna_git_haarat' \
    "2:mode:($viewModet)" \
