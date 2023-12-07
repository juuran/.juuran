#!/bin/bash
## This script pretty prints the local or remote branches based
## on date last updated.

dest=$1
## The default value is "local" branches
refsValue="refs/heads/"
if [[ $dest == "remotes" ]]; then
  refsValue="refs/remotes/"
  dest="remotes"
elif [[ $dest == "local" ]] || [[ -z $dest ]]; then
  dest="heads"
else
  >&2 echo "Unknown destination as parameter '$dest'"
  exit 2
fi

echo -e "Printing last edited branches for destination '$dest'...\n"
lines=$(git for-each-ref --sort='-committerdate:iso8601' --format='%(committerdate:relative)|%(refname:short)|%(committername)|%(authorname)' $refsValue)
[[ $dest == "remotes" ]] &&  echo -e "last edited|remote branch|committer|author\n$lines" | column -s '|' -t
[[ $dest == "heads" ]] &&    echo -e "last edited|local branch|committer|author\n$lines" | column -s '|' -t
