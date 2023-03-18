#!/bin/bash
source /home/c945fvc/.config/omat/skribat/fail.sh
noOfArgsOriginally=$(("${#@}"))
searchPath="not set";

## Optioiden käsittely (tällä kertaa "melko vaivattomasti")
while getopts "d:" OPTION; do
  case "$OPTION" in
    d)
      searchPath="$OPTARG"
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      [ "$OPTARG" = "-" ] && exitPrintError "Long options are not supported!"
      fail "Incorrect option '$OPTARG' or you forgot to specify an argument for an option that requires it."
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"


noOfArgsAfterOpts=$(("${#@}"))

if [ "$searchPath" = "not set" ]
  then
    true
  else
    [ "$searchPath" = "" ] && fail "The path given is empty."

    if [ $noOfArgsAfterOpts -gt 1 ]; then
      grep -Ir --color=always "$@" "$searchPath" 2> /dev/null | less
    elif [ $noOfArgsAfterOpts -gt 0 ]; then
      grep -Ir --color=always "$1" "$searchPath" 2> /dev/null
    else
      fail "The search criteria is required."
    fi
    exit
fi

if [[ noOfArgsOriginally -eq 1 ]]
  then grep -Ir --color=always "$1" ./* 2> /dev/null
  elif [[ $noOfArgsOriginally -gt 1 ]];
    then grep -Ir --color=always "$@" ./* 2> /dev/null | less
  else fail 'No arguments found, so maybe not worth it...?'
fi
