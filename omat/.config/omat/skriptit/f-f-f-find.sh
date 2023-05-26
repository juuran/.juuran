#!/bin/bash
source "$(dirname "$0")/fail.sh"

exactMatchesOnly=false  ## by default searches for names 'containing' search term
ignoreCase=true
X=""

printHelp() {
  echo "        f-f-f-find.sh - find for humans"
  echo "Uses find to look for files by filename recursively. Cannot access files outside user's privileges."
  echo 
  echo 'Usage:'
  echo '  f-f-f-find.sh [OPTION]... "arg1"        find a file with arg1'\''s content from current directory'
  echo '  f-f-f-find.sh [OPTION]... "arg1" arg2   find a file with arg1'\''s content from arg2'\''s directory'
  echo 
  echo 'Options (must be spelled out before "arg1"):'
  echo '  -h, --help  prints this help'
  echo '  -i          make case significant, by default it'\''s ignored'
  echo '  -e          remove implied wildcards *around* words resulting in exact matches only'
  echo '  -X          sometimes useful; keeps prints taller than terminal height usually on'
  echo '              screen (depending on whether lines occupy only one line - uses '\''less -X'\'')'
  exit
}

## Hjälp
for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

## Optioiden käsittely
while getopts "ieXh" OPTION; do
  case "$OPTION" in
    i)
      echo "        -- Case is significant --"
      ignoreCase=false
      ;;
    e)
      echo "        -- Exact matches only --"
      exactMatchesOnly=true
      ;;
    X)
      X="X"
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

[ $ignoreCase = true ] && name=iname || name=name


## Hakulogiikka (kutsutaan alempaa)
findIt() {
  local term; term="$1"
  local path; path="$2"

  pathStringLength="${#path}"
  lastChar="${path:$((pathStringLength-1)):pathStringLength}"
  if [ -d "$path" ] && [ $lastChar != "/" ]; then
    echo "( Path is a directory, appended '/' to it:  '$path/' )"
    path="${path}/"
  fi

  screenHeight=$(tput lines)

  ## HUOM! Alla olevassa blokissa ikävästi toistuu sama find lause per haarauma... Se johtuu pitkälti näiden shellien
  ## varsin epäluotettavasta tavasta käsitellä stringejä. On parempi pysyä järjissään, kuin kirjoittaa kauneinta koodia.
  if [ $exactMatchesOnly = false ]
    then
      if [[ "$term" == *"*"* ]];  ## *1
        then
          find "$path" -$name "*$term*" 2> /dev/null | less -FR$X  ## *2
        
        else
          outputHeight=$(find "$path" -$name "*$term*" 2> /dev/null | wc -l)
          if [ $outputHeight -gt $screenHeight ]
            then find "$path" -$name "*$term*" 2> /dev/null | less -FR$X -Ip "$term"
            else find "$path" -$name "*$term*" 2> /dev/null  ## *3
          fi
      fi
    
    else
      if [[ "$term" == *"*"* ]];
        then
          find "$path" -$name "$term" 2> /dev/null | less -FR$X

        else
          outputHeight=$(find "$path" -$name "$term" 2> /dev/null | wc -l)
          if [ $outputHeight -gt $screenHeight ]
            then find "$path" -$name "$term" 2> /dev/null | less -FR$X -Ip "$term"
            else find "$path" -$name "$term" 2> /dev/null
          fi
      fi
  fi
}
## *1 Tällä suodatetaan * merkit pois koska less ja find hakujen erotessa eka ruutu ei tulostu. Toimii kuin "contains (substring)".
## *2 Tämä on kompromissi. Monimutkaiset haut, joissa on * merkkejä eivät kuitenkaan tulostuisi samannäköisinä, joten valmis maalaus pois.
## *3 Samaten kompromissi. Jos alle ruudun olevalle löydökselle ajettaisiin less maalaus, tulostuisi rumasti ~ merkkejä.


noOfArgs=$#
if [ $noOfArgs -eq 1 ]; then
    findIt "$1" "./"
    exit 0

elif [ $noOfArgs -eq 2 ]; then
    path="$2"
    [ -d "$2" ] || fail "The path '$2' is not a valid directory." 2
    findIt "$1" "$2"
    exit 0
else
    fail "Incorrect amount of arguments. Type -h for help. Note that options must be placed first.\n(Complex queries are disabled, because find is difficult to use. For example the order of arguments is significant and compounding.)"
fi
