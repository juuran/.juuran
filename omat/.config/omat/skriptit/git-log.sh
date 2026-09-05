#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

function main() {
    command -v git &> /dev/null || fail 'Ohjelma `git` vaaditaan tämän skriptin ajamiseksi.'

    viewMode=1
    branch=""
    noOfArgs=$#
    cWidth=3
    opts="--decorate --color"

    if [ "$noOfArgs" -gt 2 ]; then
        fail "Väärä määrä argumentteja, vaaditaan 0-2."
    fi

    for arg in "$@"; do
        [ -z "$arg" ] && continue

        if [[ "$arg" -eq "$arg" ]]; then
            viewMode="$arg"
        else
            branch="$arg"
        fi
    done

    if [ -z "$branch" ] || [ "$branch" == "--show-current" ];
        then branch="$(git branch --show-current)"
    fi

    if      [ "$viewMode" == 1 ]; then  ## (oletus)
        git log --graph --topo-order --date='format:%d.%m.%Y-- %H:%M:%S' $opts --pretty=format:'^%C(bold dim white)%ad%C(reset)^%C(bold dim cyan)%<(19,trunc)%an%C(reset)^%C(bold cyan)%h%C(reset)^%C(auto)%D%C(reset)%n^%C(dim white)%<(19,trunc)%ar%C(reset)^%C(dim cyan)%<(19,trunc)%ae%C(reset)^%C(bold white)Commit:%C(reset)^%C(white)%s%C(reset)%n' "$branch" | column -t -s ^ -c $cWidth | less
    elif    [ "$viewMode" == 2 ]; then
        git log --graph --date-order --date='format:%d.%m.%Y-- %H:%M:%S' $opts --pretty=format:'^%C(bold dim white)%ad%C(reset)^%C(bold dim cyan)%<(19,trunc)%an%C(reset)^%C(bold cyan)%h%C(reset)^%C(auto)%D%C(reset)%n^%C(dim white)%<(19,trunc)%ar%C(reset)^%C(dim cyan)%<(19,trunc)%ae%C(reset)^%C(bold white)Commit:%C(reset)^%C(white)%s%C(reset)%n' "$branch" | column -t -s ^ -c $cWidth | less
    elif    [ "$viewMode" == 3 ]; then
        git log --graph --topo-order --abbrev-commit $opts --format=format:'^%C(bold blue)%h%C(reset)^%C(bold green)%<(15,trunc)%ar%C(reset)^%C(dim white)%<(14,trunc)%an^%C(auto)%<(28,trunc)%d^%C(white)%s%C(reset)' "$branch" | column -t -s ^ -c $cWidth | less
    elif    [ "$viewMode" == 4 ]; then
        git log --graph --date-order --abbrev-commit $opts --format=format:'^%C(bold blue)%h%C(reset)^%C(bold green)%<(15,trunc)%ar%C(reset)^%C(dim white)%<(14,trunc)%an^%C(auto)%<(28,trunc)%d^%C(white)%s%C(reset)' "$branch" | column -t -s ^ -c $cWidth | less
    elif    [ "$viewMode" == 5 ]; then
        git log --graph --topo-order --abbrev-commit $opts --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' "$branch" | less
    elif    [ "$viewMode" == 6 ]; then
        git log --graph --topo-order --date='format:%d.%m.%Y-- %H:%M:%S' $opts --pretty=format:'^%C(bold dim white)%ad%C(reset)^%C(bold dim cyan)%<(19,trunc)%an%C(reset)^%C(bold cyan)%h%C(reset)^%C(auto)%D%C(reset)%n^%C(dim white)%<(19,trunc)%ar%C(reset)^%C(dim cyan)%<(19,trunc)%ae%C(reset)^%C(bold white)Commit:%C(reset)^%C(white)%s%C(reset)%n' "$branch" | column -t -s ^ -c $cWidth | sed -r 's/\x1b\[[0-9;]*m//g' | \less -G
    else
        fail "annettua numeroa '$viewMode' ei löytynyt!"
    fi

}

main "$@"
