#!/bin/bash

source "$(dirname "$0")/fail.sh"

COLORFUL_AUTOCOMPLETE=true

## Tämä tiedosto vaaditaan jo funktioissa!
clearCache() {
  echo -n "" > "$AUTOCOMPLETE_CACHE_FILE"
  echo -n "" > "$AUTOCOMPLETE_CACHE_FILE.files"
}

AUTOCOMPLETE_CACHE_FILE="$HOME/.cache/.tasks_edit_cache"
! [ -e "$AUTOCOMPLETE_CACHE_FILE" ] && clearCache  ## jos ei ole cachea, luo cachen (ja toki myös tyhjää sen)


## ---- Funktiot ----
printHelp() {
  echo "        tasks.sh (v.1.02)"
  echo "Näyttää auki olevat täskit. Niitä voi merkata käyttämällä § merkkiä, joka jostain ihmeen syystä"
  echo "näppiksestä löytyy. Tarkempaa tietoa löytyy tiedostosta ~/notes/koodaus/tasks.txt."
  echo
  echo "SYNTAKSISTA:"
  echo "    § normaali merkintä                                 näkyy normaalilla prioriteetilla"
  echo "   §§ TÄRKEÄ merkintä                                   näkyy ensimmäisenä ja boldattuna"
  echo "   !§ tehty merkintä                                    näkyy viimeisenä ja merkattu tehdyksi"
  echo "   _§ ohitettu merkintä, jonka saatavissa näkyviin      näkyy himmeänä vivulla \"ignored\""
  echo "    § arkistoitu merkintä §                             ei näy ollenkaan millään vivulla"
  echo 
  echo "VIVUT:"
  echo "  path        näyttää koko polun tiedostoon"
  echo "  all         myös merkinnät tulevat näkyviin"
  echo "  ignored     vain \"ignoratut\" merkinnät näytetään"
  echo "  undone      vain suorittamattomat merkinnät näytetään eli poistaa suoritetut näkymästä"
  echo "  add         vaatii argumentin – lisää uuden merkinnän, käytetään: add \"pese pyykit!\""
  echo "  edit        muokkaa aiempaa merkintää tekstieditorissa (viittaa indeksillä 1:stä alkaen)"
  echo "  -h, --help  tulostaa tämän helpin"
}

addMe() {
  thingToAdd="$1"
  [[ "$thingToAdd" == *"§"* ]] || fail "Muista käyttää syntaksimerkintöjä (esim. §)! Mitään ei tallennettu."
  echo "$thingToAdd" >> "$NOTES_PATH/todo.txt"
}

printWithinScreen() {
  local printLine="$1"
  maxSize=$((SCREEN_MAX_WIDTH + SAFETY_FACTOR))
  if [[ ${#printLine} -gt $maxSize ]]
    then echo -e "${printLine:0:$((maxSize))} ...$NO_COLOR"
    else echo -e "$printLine$NO_COLOR"
  fi
}

## -- Tärkein funktio! --
printMatching() {
  local -a tasks
  local regexp="$1"
  local color="$2"
  local checkbox="$3"
  local offset="$4"
  local textColor="$NO_COLOR"
  [ -n "$5" ] && textColor="$5"
  
  shopt -s lastpipe  ## Tämä vaaditaan tai muuten muutos näkyisi vain alishellissä (jonka pipe luo ja) joka exittaa
  grep -rEn --color=never --regexp="$regexp" $SEARCH_PATH | while read -r task; do
      tasks+=( "$task" )
  done


  for task in "${tasks[@]}"; do
    taskText="$(echo $task | cut -d : -f 3-)"
    
    if    [ "$isGatherValuesForAutocomplete" == false ] && [ "$displayFilePath" == false ]; then  ## default
      file="$(echo $task | cut -d : -f 1 | xargs -L 1 basename)"
    elif  [ "$isGatherValuesForAutocomplete" == false ] && [ "$displayFilePath" == true ]; then
      file="$(echo $task | cut -d : -f 1)"
    elif  [ "$isGatherValuesForAutocomplete" == true ]; then
      file="$(echo $task | cut -d : -f 1 | xargs -L 1 basename)"
      local lineNumber; lineNumber="$(echo $task | cut -d : -f 2)"
      local fileToCache; fileToCache="$(echo $task | cut -d : -f 1)"
      fileToCache="$fileToCache:$lineNumber"
    fi
    local text="${taskText:$((2+offset))}"
    if [ $isGatherValuesForAutocomplete == false ];
      then local printLine="  ${color}${checkbox}${NO_COLOR}  (${MAGENTA}${file}${NO_COLOR}) ${textColor}${text}"  ## default
      else       printLine="  ${color}${checkbox}${NO_COLOR}  (${MAGENTA}${file}${NO_COLOR}) ${textColor}${text}${NO_COLOR}"
    fi

    if    [ "$isRendered" == true ]; then
      printWithinScreen "$printLine"
    elif  [ "$isCacheUsable" == false ]; then  ## Jos cache ei ole kunnossa, niin täytetään se uusilla tiedoilla
        if [ $COLORFUL_AUTOCOMPLETE == true ]
          then TASKS_FOR_AUTOCOMPLETE+=( "$printLine" )
          else TASKS_FOR_AUTOCOMPLETE+=( "$text" )
        fi
        FILES_FOR_AUTOCOMPLETE+=( "$fileToCache" )
    fi
  done
}

readCache() {
  readarray -t TASKS_FOR_AUTOCOMPLETE < "$AUTOCOMPLETE_CACHE_FILE"
  readarray -t FILES_FOR_AUTOCOMPLETE < "$AUTOCOMPLETE_CACHE_FILE.files"
}


writeToCache() {
  local size="${#TASKS_FOR_AUTOCOMPLETE[@]}"
  for (( i=0 ; i < $size ; i++ )); do
    echo "${TASKS_FOR_AUTOCOMPLETE[i]}" >> "$AUTOCOMPLETE_CACHE_FILE"
    echo "${FILES_FOR_AUTOCOMPLETE[i]}" >> "$AUTOCOMPLETE_CACHE_FILE.files"
  done
}

setIsCacheUsableOrClear() {
  if  [ "$(stat -c %s $AUTOCOMPLETE_CACHE_FILE)" -ne 0 ] && \
      [[ $(find "$AUTOCOMPLETE_CACHE_FILE" -newermt '-10 seconds' -print) ]]; then
        isCacheUsable=true  ## vain epätyhjä alle 10 sekuntia vanha cache sopiva
  else
        isCacheUsable=false
        clearCache
  fi
}

displayResultsForAutocomplete() {
  local size="${#TASKS_FOR_AUTOCOMPLETE[@]}"
  for (( i=0 ; i < $size ; i++ )); do
    echo -e "${TASKS_FOR_AUTOCOMPLETE[i]}"  ## tiedostopolkuja ei tässä erikseen liitetä
  done
}

editNote() {
  local index="$((($indexToEditZsh - 1)))"  ## zsh indeksointi alkaa 1:stä eikä 0:sta
  local size="${#FILES_FOR_AUTOCOMPLETE[@]}"
  [ "$index" -gt $size ] && fail "Annettu indeksi on liian suuri!"
  [ "$index" -lt 0 ] && fail "Annettu indeksi ei voi olla alle yhden!"
  
  local fileWithRow="${FILES_FOR_AUTOCOMPLETE[$index]}"
  local komento=""
  
  if where $editor &> /dev/null; then
    komento="subl $fileWithRow"
  else
    local rowNumber="$(echo $fileWithRow | cut -d : -f 2)"
    local file="$(echo $fileWithRow | cut -d : -f 1)"
    komento="nano +$rowNumber $file"
  fi
  
  echo "$komento"
  $komento
  return 0  ## Palautetaan onnistunut suoritus vaikka komento feilaisikin (esim. editori ei asennettuna)
}


## ---- Optionit eli tässä tapauksessa vivut ym esiehdot ----
for arg in "$@"; do  ## Hjälp on short-circuiting eli voi laittaa mihin vaan ja luottaa että vain tulostaa helpin
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp && exit 0
done

showNormal=true
showIgnored=false
showCompleted=true
displayFilePath=false
isRendered=true
isEditNotes=false
isGatherValuesForAutocomplete=false
isCacheUsable=false
for arg in "$@"; do
  if    [ "$arg"  == "path" ]; then
    displayFilePath=true
  elif  [ "$arg" == "all" ]; then
    showIgnored=true
  elif  [ "$arg" == "ignored" ]; then
    showIgnored=true
    showCompleted=false
    showNormal=false
  elif  [ "$arg" == "undone" ]; then
    showCompleted=false
  elif  [ "$arg" == "add" ]; then
    addMe "$2"
    break;
  elif  [ "$arg" == "edit" ] || [ "$arg" == "autocomplete_edit" ]; then  ## autocomplete_edit on piilotettu vipu
    setIsCacheUsableOrClear
    isRendered=false
    isGatherValuesForAutocomplete=true
    showIgnored=true  ## Muokkaus koskee aina kaikkia eli sama kuin "all"!

    if  [ "$arg" == "edit" ]; then
      isEditNotes=true
      [ -z "$2" ] && fail "Editointi vaatii aina argumentin, joka on indeksinumero joka viittaa johonkin merkintään."
      
      ! [[ $2 =~ ^[0-9]+$ ]] && fail "Argumentti '$2' saa sisältää vain numeromerkkejä!"
      
      indexToEditZsh="$(( 10#$2 ))"  ## erikoiskäsittely jos joukossa esim. "08" tyylisiä numeroita, jotka oikeasti oktaalilukuja
      [ "$indexToEditZsh" -eq "$indexToEditZsh" ] || fail "Muokattavan muistiinpanon viitteen on oltava numero."
      break;
    fi
  else
    fail "Vääränlainen vipu!"
  fi
done

[ -z "$NOTES_PATH" ] && NOTES_PATH="/home/c945fvc/notes"  ## Määritelään shell rc filussa. Tämä shell debug yms poikkeuksia varten!
SEARCH_PATH="$NOTES_PATH/*"
SCREEN_MAX_WIDTH=$(tput cols)
SAFETY_FACTOR=19   ## tämä on viimeinen arvo joka toimii sekä "path" että ilman. Älä pliis käytä tähän enää sekuntiakaan!
TASKS_FOR_AUTOCOMPLETE=()
FILES_FOR_AUTOCOMPLETE=()

NO_COLOR='\033[0;37m'
GREEN='\033[0;92m'
RED='\033[0;91m'
MAGENTA='\033[0;95m'
PRIORITY='\033[1;97m'
IGNORE='\033[2;97m'
DONE='\033[2;92m'
if [ $isGatherValuesForAutocomplete == true ] && [ $isEditNotes == false ] && [ "true" == "pökäle" ]; then  ## autocompleteen zsh värit!
  NO_COLOR="$(tput sgr0)"
  GREEN="$(tput 2; tput cnorm)"
  RED="$(tput 1; tput cnorm)"
  MAGENTA="$(tput 5; tput cnorm)"
  PRIORITY="$(tput setaf 7; tput bold)"
  IGNORE="$(tput 7; tput dim)"
  DONE="$(tput 2; tput dim)"
fi


## ---- Ohjelmalogiikka -----
[ "$isRendered" == true ] && echo -e "\nTämänhetkiset täskit"

## Käytetään ohituskaistaa jos juuri cachetettu tulokset, että toimisi nopeammin!
if [ "$isCacheUsable" == true ]; then
  readCache
  [ "$isEditNotes" == true ] && editNote && exit 0
  displayResultsForAutocomplete
  exit 0
fi


## regexp
start="^[^§_!]*"  ## rivin alussa ei saa syntaksimerkkejä ennen vars. sääntöä
end="[^§]*$"      ## pykälä ei saa esiintyä uudestaan vars. säännön jälkeen (käytetään arkistointiin = poistamiseen tuloksista)

## tärkeät
[ "$showNormal" == true ] && \
  printMatching "$start§{2}$end"    $PRIORITY   "[ ]"   1   $PRIORITY

## tekemättömät
[ "$showNormal" == true ] && \
  printMatching "$start§{1}$end"    $NO_COLOR   "[ ]"   0

## ignore
[ "$showIgnored" == true ] && \
  printMatching "${start}_§$end"    $IGNORE     "[ ]"   1   $IGNORE

## tehdyt
[ "$showCompleted" == true ] && \
  printMatching "$start!§$end"      $GREEN      "[x]"   1   $DONE

## vanhat väärät
  printMatching "$start§!$end"      $RED        "Virheellinen merkintä, poista!"   1

[ "$isCacheUsable" == false ] && writeToCache
[ "$isEditNotes" == true ] && editNote && exit 0
[ "$isGatherValuesForAutocomplete" == true ] && displayResultsForAutocomplete
