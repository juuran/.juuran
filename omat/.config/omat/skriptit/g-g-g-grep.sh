#!/bin/bash
source "$(dirname "$0")/fail.sh"

ignoreCase="--ignore-case"
recursive="--dereference-recursive"
grepMode="normal"
isPreChecked=true

printHelp() {
  echo "        g-g-g-grep.sh - grep for humans"
  echo "Uses grep to search for contents of files recursively. Cannot access files outside user's privileges."
  echo
  echo 'Usage:'
  echo 'Note! The "quotes" are always needed when arguments contain multiple criteria or, in paths, glob characters "?" and "*".'
  echo '  g-g-g-grep.sh [OPTION]... "arg1"                            search for arg1 from current dir'
  echo '  g-g-g-grep.sh [OPTION]... "arg1" "argN"                     search for arg1 from director[y/ies] or file(s) specified by argN'
  echo '  g-g-g-grep.sh [OPTION]... "arg1" "argN" [OPTION_TO_GREP]... search for  -""-  with n options given to grep'
  echo 
  echo 'Options:'
  echo "Note! These must be spelled out before 'arg1'!"
  echo '  -h, --help  prints this help'
  echo '  -x          display debug info – should be the first option to show all prints'
  echo '  -i          turn "--ignore-case" off which is on by default – makes case significant'
  echo '  -X          keeps printed text on screen (usually) – controls whether -X option is given to less'
  echo '  -d          change default "--dereference-recursive" into normal "--recursive", because it could help'
  echo '  -r          turn all recursion off'
  echo '  -c          zgrep is used to read compressed files which always disables unsupported recursion'
  echo '  -p          turns pre-checking off - searches are a lot faster but always return success even when they fail'
  echo
  echo "ATTENZION! 1. Quotation marks must be used when arguments contain multiple criteria or whitespace. In paths also when glob characters are used."
  echo "           2. Options in the beginning go to g-g-g-grep.sh, after that come the normal arguments, options in the end go to grep."
  echo "           3. If only one path argument (\"argN\") is given, it is handled specially: a 'dir' is appended -> 'dir/*'. This is not done for multiple"
  echo "              path names that are written inside \"quotes\"! In all cases 'dir/' and 'dir/*' are left alone."
  exit 0
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

## Optioiden käsittely
while getopts "xidrcXph" OPTION; do
  case "$OPTION" in
    x)
      echo "  -- (DEBUG: Received params when switching on debug: $*) --"
      isDebug=true
      ;;
    i)
      [ "$isDebug" == true ] && echo "  -- (DEBUG: Case is significant) --"
      ignoreCase=""
      ;;
    d)
      [ "$isDebug" == true ] && echo "  -- (DEBUG: Changed '$recursive' into '--recursive') --"
      recursive="--recursive"
      ;;
    r)
      [ "$isDebug" == true ] && echo "  -- (DEBUG: Recursion is off) --"
      recursive=""
      ;;
    c)
      [ "$isDebug" == true ] && echo "  -- (DEBUG: Compressed files are also read using zgrep) --"
      [ "$isDebug" == true ] && echo "  -- (DEBUG: Recursion is off because it is not supported in zgrep) --"
      grepMode="compressed"
      recursive=""
      ;;
    X)
      [ "$isDebug" == true ] && echo '  -- (DEBUG: Adding option "-X" to be given to grep) --'
      X="X"
      ;;
    p)
      [ "$isDebug" == true ] && echo '  -- (DEBUG: Pre-checking is off, returning success for all queries) --'
      isPreChecked=false
      ;;
    h)
      printHelp
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option '$OPTARG'. Type -h for help!" 1
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"
[ "$isDebug" == true ] && echo "  -- (DEBUG: Received params after dealing with regular options: 1=$1, 2=$2, 3=$3, 4=$4, 5=$5, 6=$6, 7=$7, 8=$8) --"


## Ohjelmalogiikka
noOfArgs=$#
if [ $noOfArgs -lt 1 ]; then
  fail 'At least one argument is needed' 2


elif [ $noOfArgs -eq 1 ]; then
  if [ $grepMode == "normal" ]
    then  grep --fixed-strings $ignoreCase $recursive --color=always "$1" ./* 2> /dev/null | less -FR$X
    else zgrep --fixed-strings $ignoreCase            --color=always "$1" ./*              | less -FR$X
  fi
  exit 0


elif [ $noOfArgs -gt 1 ]; then
  arg="$1"
  possiblyDir="$2"
  possiblyOpt="$3"
  shift 2  ## siirretään vain argumenttien verran että optiot menevät oikein suoraan grepille
  paths=()
  noOfPathsAreDirs=0
  exitWithCode=0

  [ -n "$possiblyOpt" ] && [ ${possiblyOpt:0:1} != "-" ] && fail 'The third argument is not an option. For multiple paths, or glob characters, surround them with "quotes". Type -h for help!' 2

  ## polkujen oikeellisuustarkistus
  noOfPaths="$(echo $possiblyDir | wc -w)"
  for path in $possiblyDir; do  ## tehdään näin, että globbaa jo tässä vaiheessa, koska oikeellisempi tarkistus
    if [ $noOfPaths -gt 1 ]; then
        if sudo [ -d "$path" ]; then
          noOfPathsAreDirs=$(($noOfPathsAreDirs+1))
          paths+=( "$path" )  ## tällä lisätään listan perään
        else
          if sudo [ -f "$path" ]
            then paths+=( "$path" )
            else
              error "The following is not a valid directory or file and is omitted from the search: $path"
              exitWithCode=4
          fi
        fi
    elif sudo [ -d "$path" ]; then
      paths=( "$path" )
      noOfPathsAreDirs=$(($noOfPathsAreDirs+1))
    elif [ ${path:0:1} == "-" ]; then
      paths=( "./*" )
      noOfPathsAreDirs=$(($noOfPathsAreDirs+1))
    elif sudo [ -f "$path" ]; then
      paths=( "$path" )
      else   ## jos kansioargumentti (joka esiintyy yksinään) ei ole kansio, optio taikka filu, niin se on virhe
        fail "The given dir '$path' is not a valid directory or file. Provide a correct path or see 'man grep' for grep's options." 2
    fi
  done

  if [ $noOfPaths -eq 1 ] && [ $noOfPathsAreDirs -eq 1 ]; then  ## ekalla tarkistetaan intentio (vain annettaessa monta argumenttia halutaan automaatti appendaus "/*"), toisella että oikeasti olemassa olevia polkuja
    last2Chars="${paths:$(( ${#paths}-2 ))}"
    lastChar="${paths:$(( ${#paths}-1 ))}"
    if [ $lastChar != "/" ] && [ $lastChar != "*" ] && [ $lastChar != "?" ] && [ $last2Chars != "/*" ]; then
      paths=( "$paths/*" )
      echo "( Path is a directory, appended '/*' to it:  ${paths[*]} )"
    fi
  fi

  ## pre-checking että saadaan oikeat virheet kiinni (less hävittää ne)
  exitCode=0
  if [ $isPreChecked == true ]; then
    if [ $grepMode == "normal" ]
      then sudo  grep --fixed-strings $ignoreCase $recursive --color=always "$arg" ${paths[*]} "$@" &> /dev/null
      else sudo zgrep --fixed-strings $ignoreCase            --color=always "$arg" ${paths[*]} "$@" &> /dev/null
    fi
    exitCode="$?"
    [ "$isDebug" == true ] && echo "  -- (DEBUG: exit code from grep: $exitCode) --"
  fi

  ## Varsinainen grep usealle argumentille
  if [ $grepMode == "normal" ]
    then sudo  grep --fixed-strings $ignoreCase $recursive --color=always "$arg" ${paths[*]} "$@" 2> /dev/null | less -FR$X
    else sudo zgrep --fixed-strings $ignoreCase            --color=always "$arg" ${paths[*]} "$@" 2> /dev/null | less -FR$X
  fi

  ## virheenkäsittely
  if   [ $exitCode -eq 1 ] && [ $grepMode == "compressed" ]; then  ## zgrepin virheenkäsittely
      if [ $noOfPathsAreDirs -eq 1 ] && [ $lastChar == "/" ]; then fail 'One search failed because path was a directory and zgrep does not support recursion. If you wish to search within a folder, type "dir" or "dir/*" – writing "dir/" is reserved for the literal directory in this script.' 3
      elif [ $noOfPathsAreDirs -gt 0 ];                       then fail 'At least one search failed because paths were directories and zgrep does not support recursion.' 3
      fi
  elif [ $exitCode -eq 2 ] && [ $grepMode == "normal" ]; then ## tavallisen grepin virheenkäsittely
      if   [ -z "$recursive" ] && [ $noOfPaths -eq 1 ] && [ $lastChar == "/" ];  then fail "The search failed because the path provided was a directory but recursion is off. Turn recursion on. If you wish to search within a folder, type 'dir/*' or 'dir' – writing 'dir/' is reserved for the literal directory in this script." 3
      elif [ -z "$recursive" ] && [ $noOfPathsAreDirs -eq 1 ];                          then fail "Grep exited with error and one of the paths is a dir. Try turning recursion on." 3
      elif [ -z "$recursive" ] && [ $noOfPathsAreDirs -gt 1 ];                          then fail "One or more of the searches failed because the path provided was a directory but recursion is off. Try turning recursion on." 3
      else fail "Faulty argument or option given to grep. Type 'man grep' for info about grep's options." 3
      fi
  elif [ $exitCode -eq 2 ]; then fail "Faulty argument or option given to grep. Type 'man grep' for info about grep's options." 3
  elif [ $exitWithCode -eq 4 ]; then fail "One or more path arguments were refused by the script but otherwise there were no problems." 4
  elif [ $exitCode -gt 2 ]; then fail "Failed. Neither grep nor zgrep should return a code larger than 2 but received $exitCode." 3
  fi
  exit 0
  
fi

## Exit codeja on tässä käytelty kuten:
## 0 success, ohjelma toimi kuten pitikin (löysi tai ei)
## 1 vääränlainen optioni
## 2 tämän skriptin mielestä argumenteissa vikaa
## 3 grep tai zgrep mielestä argumenteissa tai optioissa vikaa
## 4 jos piti hylätä jokin poluista, mutta ei isompaa vikaa
