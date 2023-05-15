#!/bin/bash
source "$(dirname "$0")/fail.sh"

## Yksinkertaistettu (uudelleenkirjoitettu) g-g-g-grep.sh
for arg in "$@"; do
  if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
    echo "        g-g-g-grep.sh - grep for humans"
    echo "Uses grep to search for contents of files recursively"
    echo
    echo "Usage:"
    echo '  g-g-g-grep.sh "arg1"            search for arg1'\''s content from current directory'
    echo '  g-g-g-grep.sh "arg1" arg2       search for arg1'\''s content from arg2'\''s directory'
    echo '  g-g-g-grep.sh "arg1" arg2 argN  search for arg1'\''s content from arg2'\''s directory with argN parameters given to grep'
    exit
  fi
done

noOfArgs=$#

if [ $noOfArgs -lt 1 ]; then
  fail 'At least one argument is needed'
elif [ $noOfArgs -eq 1 ]; then
  grep --fixed-strings --ignore-case --dereference-recursive --color=always "$1" ./* 2> /dev/null | less -FR
elif [ $noOfArgs -gt 1 ]; then
  grep --fixed-strings --ignore-case --dereference-recursive --color=always "$@" 2> /dev/null | less -FR
fi
