#!/bin/bash

# echo "shorthand for    \"find ./* -iname $1\"    aka Fast-From-Folder_Find"
if [[ "$1" == "$@" ]]  ## jos vain yksi argumentti
  then find ./ -iname "$1" 2> /dev/null
  else find ./ "$@"
fi

