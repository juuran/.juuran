#!/usr/bin/env bash
#compdef git-log.sh

if [[ -n "$ZSH_VERSION" ]]; then
    ## zsh

    function _anna_git_haarat() {
        haarat=()
        if command -v git &> /dev/null; then
            ## Tällaisella loitsulla zsh:ssä otetaan taulukko joka katkaistu \n kohdalta:
            IFS=$'\n' haarat=( $(git branch --format='%(refname:short)') )
        fi
        haarat+=( "--all" "--show-current" )

        _describe -t output 'gitin haarat' haarat
    }

    viewModet='( 1\:"väljä ja selkeä tyyli (oletus, topologian mukaan)" 2\:"väljä ja selkeä tyyli (ajan mukaan)"  3\:"selkeä yksirivinen tyyli (topologian mukaan)" 4\:"selkeä yksirivinen tyyli (ajan mukaan)" 5\:"legacy yksirivinen tyyli, joka näyttää \"ref\":it lyhentämättöminä" 6\:"sama kuin ensimmäinen mutta väreittä" )'

    _arguments -s \
        '1:haarat:_anna_git_haarat' \
        "2:mode:($viewModet)" \

else
    ## bash

    setCompletion() {
        completions="$1"
        COMPREPLY=($(compgen -W "$completions" -- "${COMP_WORDS[$COMP_CWORD]}"))
    }

    function _git_log() {
        local currentArgIndex="$COMP_CWORD"

        if [[ "$currentArgIndex" -eq 1 ]]; then
            if command -v git &> /dev/null; then
                git_branches="$(git branch --format='%(refname:short)')"
            fi
            setCompletion "$git_branches --all --show-current"
        elif [[ "$currentArgIndex" -eq 2 ]]; then
            setCompletion "1 2 3 4 5 6"
        fi
    }

    ## tällä tavoin toimii kutsuttaessa sekä koko nimellä (*.sh) että aliaksena
    complete -o nosort -F _git_log git-log
    complete -o nosort -F _git_log git-log.sh

fi
