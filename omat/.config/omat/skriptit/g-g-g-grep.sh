#!/bin/bash
source "$(dirname "$0")/fail.sh"

ignoreCase="--ignore-case"
recursive="--dereference-recursive"
## (Ei enää) yksinkertaistettu, mutta täysin uudelleenkirjoitettu g-g-g-grep.sh
printHelp() {
  echo "        g-g-g-grep.sh - grep for humans"
  echo "Uses grep to search for contents of files recursively. Cannot access files outside user's privileges."
  echo
  echo "Usage:"
  echo '  g-g-g-grep.sh [OPTION]... "arg1"            search for arg1'\''s content from current directory'
  echo '  g-g-g-grep.sh [OPTION]... "arg1" arg2       search for arg1'\''s content from arg2'\''s directory'
  echo '  g-g-g-grep.sh [OPTION]... "arg1" arg2 argN  search for arg1'\''s content from arg2'\''s directory with argN parameters given to grep'
  echo
  echo 'Options (must be spelled out before "arg1"):'
  echo '  -h, --help  prints this help'
  echo '  -i          turn "--ignore-case" off which is on by default - makes case significant'
  echo '  -X          keeps printed text on screen (usually) - controls whether -X option is given to less'
  echo '  -r          change "--dereference-recursive" into normal "--recursive", because it could help'
  echo '  -d          turn all recursion off'
  echo '  -x          display debug print'
  echo
  echo "ATTENZION! Options in the beginning go to g-g-g-grep.sh, options in the end go to grep (except -h which always prints this help)!"
  exit
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

## Optioiden käsittely
while getopts "irdXxh" OPTION; do
  case "$OPTION" in
    i)
      echo "        -- Case is significant --"
      ignoreCase=""
      ;;
    r)
      recursive="--recursive"
      ;;
    d)
      recursive=""
      ;;
    X)
      X="X"
      ;;
    x)
      echo "  -- (DEBUG: Received params as a whole at this moment: $*) --"
      isDebug=true
      ;;
    h)
      printHelp
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option '$OPTARG'. Type -h for help!"
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"

[ "$isDebug" == true ] && echo "  -- (DEBUG: Received params separately after shift: 1=$1, 2=$2, 3=$3, 4=$4, 5=$5, 6=$6, 7=$7, 8=$8) --"


## Ohjelmalogiikka
noOfArgs=$#
if [ $noOfArgs -lt 1 ]; then
  fail 'At least one argument is needed'

elif [ $noOfArgs -eq 1 ]; then
  grep --fixed-strings $ignoreCase $recursive --color=always "$1" ./* 2> /dev/null | less -FR$X
  exit 0

elif [ $noOfArgs -gt 1 ]; then
  possiblyPath="$2"
  ! [ -d "$possiblyPath" ] && [ ${possiblyPath:0:1} != "-" ] && fail "The path '$possiblyPath' is not a valid directory." 2
  
  ## dry run että saadaan oikeat virheet kiinni (less hävittää ne)
  grep --fixed-strings $ignoreCase $recursive --color=always "$@" &> /dev/null
  exitCode="$?"
  [ "$isDebug" == true ] && echo "  -- (DEBUG: exit code from grep: $exitCode) --"
  [ $exitCode -eq 2 ] && fail "Faulty argument or option given to grep. Try 'man grep' for more info." 3
  grep --fixed-strings $ignoreCase $recursive --color=always "$@" 2> /dev/null | less -FR$X
  exit 0
  
fi
