#!/bin/bash
source "$(dirname "$0")/fail.sh"

## Yksinkertaistettu (uudelleenkirjoitettu) g-g-g-grep.sh
for arg in "$@"; do
  if [ "$arg" == "-x" ]; then
    echo "  -- (DEBUG: Received params as a whole: '$*') --"
    isDebug=true
    shift
  fi
  if [ "$arg" == "-X" ]; then
    X="X"
    shift
  fi
  if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
    echo "        g-g-g-grep.sh - grep for humans"
    echo "Uses grep to search for contents of files recursively"
    echo
    echo "Usage:"
    echo '  g-g-g-grep.sh "arg1"            search for arg1'\''s content from current directory'
    echo '  g-g-g-grep.sh "arg1" arg2       search for arg1'\''s content from arg2'\''s directory'
    echo '  g-g-g-grep.sh "arg1" arg2 argN  search for arg1'\''s content from arg2'\''s directory with argN parameters given to grep'
    echo 'Options (must be spelled out before "arg1"):'
    echo '  -x    display debug print'
    echo '  -X    if the -X option is to be given to grep which keeps printed text on screen'
    exit
  fi
done

[ $isDebug == true ] && echo "  -- (Received params separately after shift: 1=$1, 2=$2, 3=$3, 4=$4, 5=$5, 6=$6, 7=$7, 8=$8) --"

noOfArgs=$#

if [ $noOfArgs -lt 1 ]; then
  fail 'At least one argument is needed'
elif [ $noOfArgs -eq 1 ]; then
  grep --fixed-strings --ignore-case --dereference-recursive --color=always "$1" ./* 2> /dev/null | less -FR$X
elif [ $noOfArgs -gt 1 ]; then
  path="$2"
  [ -d "$path" ] || fail "The path '$path' is not a valid directory." 2
  grep --fixed-strings --ignore-case --dereference-recursive --color=always "$@" 2> /dev/null | less -FR$X
fi
