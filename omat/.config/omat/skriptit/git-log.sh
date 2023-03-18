#!/bin/bash
whichGitLog=$1
## Jos 1. parametri annettu, siirretään parametreja yhdellä niin $@ palauttaa parametrit 2. lähtien
[[ -n $whichGitLog ]] && shift 1

if    [[ $whichGitLog == 1 ]] || [[ -z $whichGitLog ]] ; then
  git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' "$@"
elif  [[ $whichGitLog == 2 ]]; then
  git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' "$@"
else echo "Valitse katselumoodi: 1 tai 2"
fi
