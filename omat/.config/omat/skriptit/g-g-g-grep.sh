#!/bin/bash
source "$SKRIPTIT_POLKU/fail.sh"

IC="--ignore-case"
RECURSIVE="--recursive"
PTTRN_SNTX="--fixed-strings"
COLOR="--color=always"
GREP_MODE="normal"
L=""
A=""
B=""
E=""

printHelp() {
  echo ""
  echo "g-g-g-grep.sh - grep for humans (v.1.01)"
  echo ""
  echo "Uses grep to search for contents of files recursively. Cannot access files outside of user's privileges."
  echo ""
  echo "Usage:"
  echo '    g-g-g-grep.sh [OPTION]... "arg1"                               search for arg1 ("quoted" if whitespace) from current dir'
  echo '    g-g-g-grep.sh [OPTION]... "arg1" [OPTION_TO_GREP]...           search for arg1 from current dir with n options given to grep'
  echo '    g-g-g-grep.sh [OPTION]... "arg1" "argN" [OPTION_TO_GREP]...    search for arg1 from argN paths with n options given to grep'
  echo ""
  echo "ATTENZION! Options in the beginning are handled by this script but options AFTER args are fed straight to grep!"
  echo "           E.g. to list files with 'bob' exluding .txt files:    g-g-g-grep.sh bob --exclude='*.txt' --files-with-matches"
  echo ""
  echo "Options:"
  echo "    -h, --help  prints this help"
  echo "    -i          turn \"--ignore-case\" off which is on by default – makes case significant"
  echo "    -d          change default \"--recursive\" into \"--dereference-recursive\", because it could help"
  echo "    -l          number of lines to print before and after (essentially -A \$samenumber -B \$samenumber given to grep)"
  echo "    -r          turn all recursion off - useful when feeding a list of filenames and are unsure if directories are involved"
  echo "    -c          zgrep is used to read compressed files which always disables unsupported recursion"
  echo "    -E          changes the search argument to be interpreted as an extended regular expressions (ERE) instead of a string"
  echo "    -X          keeps printed text on screen (usually) – controls whether -X option is given to less"
  echo ""
  exit 0
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

## Optioiden käsittely
while getopts "il:drcXEh" OPTION; do
  case "$OPTION" in
    i)
      IC=""
      ;;
    l)
      L="$OPTARG"
      [ "$L" -eq "$L" ] || fail "Argument given must be a number!"
      A="-A"
      B="-B"
      ;;
    d)
      RECURSIVE="--dereference-recursive"
      ;;
    r)
      RECURSIVE=""
      ;;
    c)
      GREP_MODE="compressed"
      RECURSIVE=""
      ;;
    X)
      X="X"
      ;;
    E)
      PTTRN_SNTX="--extended-regexp"
      E="-e"
      ;;
    h)
      printHelp
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option \"$OPTARG\". Type -h for help!" 3
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"

## Ohjelmalogiikka (uudelleenkirjoitettu ja yksinkertaistettu)
main() {
    local paths exitCode noOfArgs eitherDirOrOpt

    ## määritetään tämä .rc tiedostoissa, mutta esimerkiksi näin
    #export GREP_COLORS="mt=7;33:fn=2;34:ln=2;33:cx=0:bn=0:se=0"

    paths=()
    exitCode=0
    noOfArgs=$#
    if [ "$noOfArgs" -lt 1 ]; then
        fail "At least one argument is needed" 3


    elif [ "$noOfArgs" -eq 1 ]; then
        if [ "$GREP_MODE" == "normal" ]; then
            [ -z "$RECURSIVE" ] && fail "Missing path! When using -r flag, a file or list of files must be given. Otherwise grep would try to search from ./ which is a path in itself."
            
                 grep  $PTTRN_SNTX $IC $B $L $A $L $RECURSIVE $COLOR $E "$1" ./  | less -FRM$X $IC;  exitCode="${PIPESTATUS[0]}"
            else zgrep $PTTRN_SNTX $IC $B $L $A $L            $COLOR $E "$1" ./  | less -FRM$X $IC;  exitCode="${PIPESTATUS[0]}"
        fi

    elif [ "$noOfArgs" -gt 1 ]; then
        arg="$1"
        eitherDirOrOpt="$2"
        [ -z "$eitherDirOrOpt" ] && fail "The second argument cannot be empty!" 3

        if [ "${eitherDirOrOpt:0:1}" == "-" ]; then
            # paths=( "./*" )
            shift 1             ## jos kyseessä on optioni, niin se halutaan siirtää suoraan grepille ...
        else
            paths=( "${eitherDirOrOpt[@]}" )
            shift 2             ## ... jos taas polku niin, pistetään talteen ja mahdolliset grep optiot sen jälkeen
        fi

    ## grep usealle argumentille (kelan koneet ei tue zgrepin kanssa argumentteja loppuun, siksi tällä tyylillä)
        if   [ "$GREP_MODE" == "normal" ];     then  grep $PTTRN_SNTX $IC $B $L $A $L $RECURSIVE $COLOR      $E "$arg" ${paths[@]} "$@" | less -FRM$X $IC;  exitCode="${PIPESTATUS[0]}"
        elif [ "$GREP_MODE" == "compressed" ]; then zgrep $PTTRN_SNTX $IC $B $L $A $L            $COLOR "$@" $E "$arg" ${paths[@]}      | less -FRM$X $IC;  exitCode="${PIPESTATUS[0]}"
        fi

    fi

    if [ "$exitCode" -eq 141 ]
        then exit 0
        else exit $exitCode
    fi
}

main "$@"
