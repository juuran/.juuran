#!/bin/bash
source "$(dirname "$0")/fail.sh"

iC="--ignore-case"
recursive="--dereference-recursive"
patternSyntax="--fixed-strings"
color="--color=always"
grepMode="normal"

printHelp() {
  echo "\
        g-g-g-grep.sh - grep for humans
Uses grep to search for contents of files recursively. Cannot access files outside user's privileges.

Usage:
    g-g-g-grep.sh [OPTION]... \"arg1\"                            search for arg1 (with quotes if contains whitespace) from current dir
    g-g-g-grep.sh [OPTION]... \"arg1\" [OPTION_TO_GREP]...        search for arg1 from current dir with n options given to grep
    g-g-g-grep.sh [OPTION]... \"arg1\" \"argN\" [OPTION_TO_GREP]... search for arg1 from argN paths with n options given to grep

ATTENZION! Options in the beginning are handled by this script but options after args are fed straight to grep!

Options:
    -h, --help  prints this help
    -i          turn \"--ignore-case\" off which is on by default – makes case significant
    -X          keeps printed text on screen (usually) – controls whether -X option is given to less
    -d          change default \"--dereference-recursive\" into normal \"--recursive\", because it could help
    -r          turn all recursion off
    -c          zgrep is used to read compressed files which always disables unsupported recursion
    -E          changes the search argument to be interpreted as an extended regular expressions (ERE) instead of a string\
"
  exit 0
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

## Optioiden käsittely
while getopts "xidrcXES:h" OPTION; do
  case "$OPTION" in
    i)
      iC=""
      ;;
    d)
      recursive="--recursive"
      ;;
    r)
      recursive=""
      ;;
    c)
      grepMode="compressed"
      recursive=""
      ;;
    X)
      X="X"
      ;;
    E)
      patternSyntax="--extended-regexp"
      e="-e"
      ;;
    h)
      printHelp
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option '$OPTARG'. Type -h for help!" 3
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"


## Ohjelmalogiikka (uudelleenkirjoitettu ja yksinkertaistettu)
exitCode=0
noOfArgs=$#
if [ $noOfArgs -lt 1 ]; then
  fail 'At least one argument is needed' 3

elif [ $noOfArgs -eq 1 ]; then
  if [ $grepMode == "normal" ]
    then  grep $patternSyntax $iC $recursive $color $e "$1" ./* | less -FR$X $iC;  exitCode="${PIPESTATUS[0]}"
    else zgrep $patternSyntax $iC            $color $e "$1" ./* | less -FR$X $iC;  exitCode="${PIPESTATUS[0]}"
  fi

elif [ $noOfArgs -gt 1 ]; then
  arg="$1"
  eitherDirOrOpt="$2"
  [ -z "$eitherDirOrOpt" ] && fail "The second argument can't be empty!" 3

  if [ ${eitherDirOrOpt:0:1} == "-" ]; then
    possiblyDir="./*"
    shift 1             ## jos kyseessä on optioni, niin se halutaan siirtää suoraan grepille ...
  else
    possiblyDir="$2"
    shift 2             ## ... jos taas polku niin, pistetään talteen ja mahdolliset grep optiot sen jälkeen
  fi
  paths=( "${possiblyDir[@]}" )

  ## grep usealle argumentille (kelan koneet ei tue zgrepin kanssa argumentteja loppuun, siksi tällä tyylillä)
  if   [ $grepMode == "normal" ];     then  grep $patternSyntax $iC $recursive $color $e      "$arg" ${paths[@]} "$@" | less -FR$X $iC;  exitCode="${PIPESTATUS[0]}"
  elif [ $grepMode == "compressed" ]; then zgrep $patternSyntax $iC            $color "$@" $e "$arg" ${paths[@]}      | less -FR$X $iC;  exitCode="${PIPESTATUS[0]}"
  fi

fi

if [ $exitCode -eq 141 ]
  then exit 0
  else exit $exitCode
fi
