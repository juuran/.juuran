#!/bin/bash
source ~/.config/omat/skriptit/fail.sh
exactMatchesOnly=true
ignoreCase=true

## Optioiden käsittely
while getopts "ie" OPTION; do
  case "$OPTION" in
    i)
      echo "        -- Case is significant --"
      ignoreCase=false
      ;;
    e)
      echo "        -- Exact matches only --"
      exactMatchesOnly=false
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option '$OPTARG'. Correct ones are:\n    -i    To make cases significant. By default case is ignored.\n    -e    Only exact matches are returned without \"implied wildcards\" on search term."
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"

numberOfArguments=$(("${#@}"))  ## number of "normal" arguments – i.e. arguments after handling options
[ $numberOfArguments -ne 1 ] && fail "Only exactly one argument is supported. Use regular find for more complex queries."

[ $ignoreCase = true ] && name=iname || name=name

if [ $exactMatchesOnly = true ]
  then find ./ -$name "*$1*" 2> /dev/null   ## "generous" search, find everything
  else find ./ -$name "$1" 2> /dev/null     ## "non-generous" search, find exact matches only
fi
