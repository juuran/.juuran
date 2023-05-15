#!/bin/bash
source "$(dirname "$0")/fail.sh"

exactMatchesOnly=false  ## by default searches for names 'containing' search term
ignoreCase=true

## Hjälp
for arg in "$@"; do
  if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
    echo "        f-f-f-find.sh - find for humans"
    echo "Uses find to look for files by filename recursively"
    echo 
    echo 'Usage:'
    echo '  f-f-f-find.sh [OPTION]... "arg1"        find a file with arg1'\''s content from current directory'
    echo '  f-f-f-find.sh [OPTION]... "arg1" arg2   find a file with arg1'\''s content from arg2'\''s directory'
    echo 
    echo 'Options (must be spelled out before "arg1"):'
    echo '  -i    make case significant, by default it'\''s ignored'
    echo '  -e    remove implied wildcards *around* words resulting in exact matches only'
    exit
  fi
done

## Optioiden käsittely
while getopts "ie" OPTION; do
  case "$OPTION" in
    i)
      echo "        -- Case is significant --"
      ignoreCase=false
      ;;
    e)
      echo "        -- Exact matches only --"
      exactMatchesOnly=true
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option '$OPTARG'. Type -h for help!"
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"

[ $ignoreCase = true ] && name=iname || name=name

## Hakulogiikka
findIt() {
  local term; term="$1"
  local path; path="$2"

  echo "Seuraavan tulosteen pitäisi testata, onko kys merkki hakusanassa"
  [[ "$term" == *"*"* ]] && echo true || echo false

  if [ $exactMatchesOnly = false ]
    then
      [[ "$term" == *"\*"* ]] && find "$path" -$name "*$term*" 2> /dev/null | less -FRX -Ip "$term" || \
                                 find "$path" -$name "*$term*" 2> /dev/null | less -FRX
    else
      [[ "$term" == *"\*"* ]] && find "$path" -$name "$term" 2> /dev/null   | less -FRX -p "$term" || \
                                 find "$path" -$name "$term" 2> /dev/null   | less -FRX
  fi
}

noOfArgs=$#
if [ $noOfArgs -eq 1 ];   then findIt "$1" "./"
elif [ $noOfArgs -eq 2 ]; then findIt "$1" "$2"
else fail "Incorrect amount of arguments. Options must be placed first. Type -h for help. (The order of arguments is significant in find making it difficult to use.)"
fi
