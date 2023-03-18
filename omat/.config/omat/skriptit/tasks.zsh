#!/bin/zsh
## Ai että. Kyllä siitä aika kaunis tuli vaikka itse sanonkin! Kyllähän tähän enemmän aikaa
## paloi, kuin oli alunperin tarkoitus... Mutta nyt ainakin toimii listaus kaikista tiedostoista
## ilman mitään häslinkiä ja voi luottaa, ettei ole duplikaatteja! Opinpahan reg expistä taas
## lisää sitä paitsi. Kyllä siinä pärjää ihan hyvin ilman capture groupejakin.

SEARCH_PATH='/home/c945fvc/notes/'
NO_COLOR='\033[0m'
GREEN=$(tput setaf 83)
RED='\033[0;91m'
MAGENTA=$(tput setaf 134)
PRIORITY='\033[1;97m'
IGNORE='\033[2;97m'
DONE=$(tput setaf 71)
SCREEN_MAX_WIDTH=$(tput cols)
SAFETY_FACTOR=19   ## tämä on viimeinen arvo joka toimii sekä "path" että ilman. Älä pliis käytä tähän enää sekuntiakaan!
# PRINTABLE_WIDTH_MAX=$(($(tput cols) + 3))   ## värien käyttö jotenkin sotkee, kikkailtava... 3 suurin mikä toimii nyt...?

showIgnored=false
showCompleted=true
showFilePath=false
for arg in $@; do
  [[ $arg == fullPath ]] || [[ $arg  == fullpath ]] || [[ $arg  == path ]] || [[ $arg  == fp ]] && showFilePath=true
  [[ $arg == all ]] || [[ $arg == full ]] || [[ $arg == ignored ]] && showIgnored=true
  [[ $arg == undone ]] || [[ $arg == short ]] || [[ $arg == brief ]] || [[ $arg == summary ]] && showCompleted=false
done

printWithinScreen() {
  local line=$1
  maxSize=$((SCREEN_MAX_WIDTH + SAFETY_FACTOR))
  [[ ${#line} -gt $maxSize ]] && \
    echo -e "${printLine:0:$((maxSize))} ...$NO_COLOR" || \
    echo -e "$printLine$NO_COLOR"
}

printMatching() {
  regexp=$1
  color=$2
  checkbox=$3
  offset=$4
  [[ -n $5 ]] && textColor=$5 || textColor=$NO_COLOR
  
  grep -rE -h --color=never --regexp="$regexp" $SEARCH_PATH | while read -r task
    do
      [[ $showFilePath == true ]] && \
        file=$(grep -lr "$task" $SEARCH_PATH) || \
        file=$(grep -lr "$task" $SEARCH_PATH | xargs -L 1 basename)
      text=${task:$((2+offset))}
      printLine="  ${color}${checkbox}${NO_COLOR}  (${MAGENTA}${file}${NO_COLOR}) ${textColor}${text}"
      printWithinScreen "$printLine"
    done
}


echo -e "\nTämänhetkiset täskit"
start=^[^§_!]*  ## rivin alussa ei saa syntaksimerkkejä ennen vars. sääntöä
end=[^§]*$      ## pykälä ei saa esiintyä uudestaan vars. säännön jälkeen (käytetään arkistointiin = poistamiseen tuloksista)
## tärkeät
printMatching "$start§{2}$end"    $PRIORITY   "[ ]"   1   $PRIORITY

## tekemättömät
printMatching "$start§{1}$end"    $NO_COLOR   "[ ]"   0

## ignore
[[ $showIgnored == true ]] && \
printMatching "${start}_§$end"    $IGNORE     "[ ]"   1   $IGNORE

## tehdyt
[[ $showCompleted == "true" ]] && \
printMatching "$start!§$end"      $GREEN      "[x]"   1   $DONE

## vanhat väärät
printMatching "$start§!$end"      $RED        "Virheellinen merkintä, poista!"   1
