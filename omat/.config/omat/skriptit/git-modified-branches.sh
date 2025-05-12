#!/bin/bash
## This script pretty prints the local or remote branches based
## on date last updated.

source "$(dirname "$0")/fail.sh"

dest=$1
if [[ $dest == "remotes" ]]; then
  refsValue="refs/remotes/"
elif [[ $dest == "heads" ]]; then
  refsValue="refs/heads/"
elif [[ -z $dest ]] || [[ $dest == "local" ]]; then
  echo "No parameter or 'local' given, showing local branches"
  dest="heads"
  refsValue="refs/heads/"
else
  fail "Unknown destination as parameter '$dest'" 2
fi

echo -e "Printing last edited branches for destination $dest ('$refsValue')...\n"
lines=$(git for-each-ref --sort='-committerdate:iso8601' --format='%(committerdate:relative)|%(refname:short)|%(committername)|%(authorname)' $refsValue)
## error value ei tässä kerro mitään, joten katsotaan onko tullut printtiä
[[ -z $lines ]] && fail "Nothing was received from 'git for-each-ref' so exiting with error"

if [ $dest == "remotes" ]; then
  echo -e "last edited|remote branch|committer|author\n$lines" | column -s '|' -t
elif [ $dest == "heads" ]; then
  echo -e "last edited|local branch|committer|author\n$lines" | column -s '|' -t
fi
