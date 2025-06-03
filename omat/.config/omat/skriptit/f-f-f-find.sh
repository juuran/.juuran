#!/bin/bash
source "$SKRIPTIT_POLKU/fail.sh"

exactMatchesOnly=false  ## oletuksena etsii "sisältää" periaatteella, tällä vain täsmälliset mätsit
iCLess="--ignore-case"
iCFind="i"
type="wholename"
maxdepth=""
l=""
X=""

printHelp() {
  echo "        f-f-f-find.sh - find for humans (v.1.02)"
  echo "Uses find to look for files by filename recursively. Cannot access files outside privileges of current user."
  echo 
  echo "Usage:"
  echo "  f-f-f-find.sh [OPTION]... \"ARG1\"        find files with \"ARG1\" content from current directory"
  echo "  f-f-f-find.sh [OPTION]... \"ARG1\" ARG2   find files with \"ARG1\" content from \"ARG2\" directory (only one path allowed!)"
  echo
  echo "    ARG1:   >> search term <<"
  echo "    ARG2:   >> path to start from <<"
  echo 
  echo "Options (must be spelled out before "ARG1"):"
  echo "  -h, --help  prints this help"
  echo "  -i          make case significant, by default case is ignored"
  echo "  -e          exact matches only by removing wildcards  *  around words"
  echo "  -m          maxdepth, i.e. the amount how deep to descend in path recursion (infinite by default)"
  echo "  -X          prints taller than terminal height are kept on screen if they occupy only one line (less -X)"
  exit
}

## Hjälp
for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

## Optioiden käsittely
while getopts "ieXhm:" OPTION; do
  case "$OPTION" in
    i)
      echo "        -- Case is significant --"
      iCLess=""
      iCFind=""
      ;;
    e)
      echo "        -- Exact matches only --"
      exactMatchesOnly=true
      type="name"
      ;;
    X)
      X="X"
      ;;
    h)
      printHelp
      ;;
    m)
      maxdepth="-maxdepth"
      l="$OPTARG"
      [ "$l" -eq "$l" ] || fail "The value for maxdepth must be a number!"
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option "$OPTARG". Type -h for help!"
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"


## Hakulogiikka (kutsutaan alempaa)
findIt() {
  local term; term="$1"
  local path; path="$2"

  pathStringLength="${#path}"
  lastChar="${path:$((pathStringLength-1)):pathStringLength}"
  if [ -d "$path" ] && [ $lastChar != "/" ]; then
    ## kyseessä polku, lisätään / perään
    path="${path}/"
  fi

  screenHeight=$(tput lines)

  ## HUOM! Alla olevassa blokissa ikävästi toistuu sama find lause per haarauma... Se johtuu pitkälti näiden shellien
  ## varsin epäluotettavasta tavasta käsitellä stringejä. On parempi pysyä järjissään, kuin kirjoittaa kauneinta koodia.
  if [ $exactMatchesOnly = false ]
    then
      if [[ "$term" == *"*"* ]];  ## *1
        then
          find "$path" -$type "*$term*" $maxdepth $l 2> /dev/null | less -FRM$X $iCLess  ## *2
        
        else
          outputHeight=$(find "$path" -$type "*$term*" $maxdepth $l 2> /dev/null | wc -l)
          if [ $outputHeight -gt $screenHeight ]
            then find "$path" -$type "*$term*" $maxdepth $l 2> /dev/null | less -FRM$X $iCLess -p "$term"
            else find "$path" -$type "*$term*" $maxdepth $l 2> /dev/null  ## *3
          fi
      fi
    
    else
      if [[ "$term" == *"*"* ]];
        then
          find "$path" -$type "$term" $maxdepth $l 2> /dev/null | less -FRM$X $iCLess

        else
          outputHeight=$(find "$path" -$type "$term" $maxdepth $l 2> /dev/null | wc -l)
          if [ $outputHeight -gt $screenHeight ]
            then find "$path" -$type "$term" $maxdepth $l 2> /dev/null | less -FRM$X $iCLess -p "$term"
            else find "$path" -$type "$term" $maxdepth $l 2> /dev/null
          fi
      fi
  fi
}
## *1 Tällä suodatetaan * merkit pois koska less ja find hakujen erotessa eka ruutu ei tulostu. Toimii kuin "contains (substring)".
## *2 Tämä on kompromissi. Monimutkaiset haut, joissa on * merkkejä eivät kuitenkaan tulostuisi samannäköisinä, joten valmis maalaus pois.
## *3 Samaten kompromissi. Jos alle ruudun olevalle löydökselle ajettaisiin less maalaus, tulostuisi rumasti ~ merkkejä.

type="${iCFind}${type}"
noOfArgs=$#
if [ $noOfArgs -eq 1 ]; then
    findIt "$1" "./"
    exit 0

elif [ $noOfArgs -eq 2 ]; then
    arg="$1"
    path="$2"
    [ -d "$path" ] || fail "The path \"$path\" is not a valid directory." 2
    findIt "$arg" "$path"
    exit 0
else
    fail "Incorrect amount of arguments. Type -h for help. Note that options must be placed first.\n(Complex queries are disabled, because find is difficult to use. For example the order of arguments is significant and compounding.)"
fi
