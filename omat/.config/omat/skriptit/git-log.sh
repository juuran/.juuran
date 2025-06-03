#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

viewMode=1
branch=""
noOfArgs=$#
cWidth=3
opts="--decorate --color"
example="Example of a correct way:\n    git-log <branch (opt)> <viewmode 1-5 (opt)>"

if [ "$noOfArgs" -gt 2 ]; then
    fail "Erroneous amount of arguments. Required 0-2 arguments. $example"
fi

for arg in "$@"; do
    [ -z "$arg" ] && continue
    
    if [[ "$arg" =~ ^[1-5]{1}$ ]]; then
        viewMode="$arg"
    elif [[ "$arg" =~ ^[6-9]+$ ]] || [[ "$arg" =~ ^[0]+[0-9]*$ ]] || [[ "$arg" =~ ^[1-5]+[0-9]+$ ]]; then
        fail "Only numbers 1-5 are allowed for viewmode. $example"
    else
        branch="$arg"
    fi
done

if [ -z "$branch" ] || [ "$branch" == "--show-current" ]; then branch="$(git branch --show-current)"
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
fi
