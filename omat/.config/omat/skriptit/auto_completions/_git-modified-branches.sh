#!/usr/bin/env bash
#compdef git-modified-branches.sh

if [[ -n "$ZSH_VERSION" ]]; then
    ## zsh

    komennot=( "remotes:show results for remote branhces on the server" "local:(default) branches or \"heads\" stored locally" )
    _describe komennot komennot

else
    ## bash

    function _git_modified_branches() {
        completions="remotes local"
        COMPREPLY=($(compgen -W "$completions" -- "${COMP_WORDS[$COMP_CWORD]}"))
    }

    ## tällä tavoin toimii kutsuttaessa sekä koko nimellä (*.sh) että aliaksena
    complete -o nosort -F _git_modified_branches git-modified-branches
    complete -o nosort -F _git_modified_branches git-modified-branches.sh

fi
