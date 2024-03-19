#!/bin/bash

source "$(dirname "$0")/fail.sh"

COLORFUL_AUTOCOMPLETE=true
[ -z "$NOTES_PATH" ] && NOTES_PATH="/home/c945fvc/notes"
SEARCH_PATH="$NOTES_PATH/*"
SCREEN_MAX_WIDTH=$(tput cols)
SAFETY_FACTOR=19   ## tämä on viimeinen arvo joka toimii sekä "path" että ilman. Älä pliis käytä tähän enää sekuntiakaan!
CACHE_VALID_MAX_SECONDS=3
TASKS_FOR_AUTOCOMPLETE=()
FILES_FOR_AUTOCOMPLETE=()

## Tämä tiedosto vaaditaan jo funktioissa!
clearCache() {
  echo -n "" > "$AUTOCOMPLETE_CACHE_FILE"
  echo -n "" > "$AUTOCOMPLETE_CACHE_FILE.files"
}

AUTOCOMPLETE_CACHE_FILE="$HOME/.cache/.tasks_edit_cache"
! [ -e "$AUTOCOMPLETE_CACHE_FILE" ] && clearCache  ## jos ei ole cachea, luo cachen (ja toki myös tyhjää sen)


## ---- Funktiot ----
printHelp() {
  echo "        tasks.sh (v.1.22)"
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
  echo "  add         vaatii argumentiksi merkinnän, jossa on käytettävä oikeaa syntaksia, toisena"
  echo '              argumenttina vapaaehtoinen suhteellinen polku joka määritetty env varilla $NOTES_PATH'
  echo "  edit        muokkaa aiempaa merkintää tekstieditorissa (viittaa indeksillä 1:stä alkaen)"
  echo "  -h, --help  tulostaa tämän helpin"
}

addMe() {
  thingToAdd="$1"
  pathToFile="$NOTES_PATH/$2"
  [[ "$thingToAdd" == *"§"* ]] || fail "Muista käyttää syntaksimerkintöjä (esim. §)! Mitään ei tallennettu."
  echo "$thingToAdd" >> "$pathToFile"  || fail "Merkintää ei voitu tallentaa."
}

printWithinScreenWithColors() {
  local beginningPart="  ${checkbox}  (${file}) "
  local endPart="$text"
  local finalPrintWithoutColor="${beginningPart}${endPart}"
  if [ "$isGatherValuesForAutocomplete" == true ] && [ "$isCacheUsable" == false ]; then
    quadraticWidthEmphasis=$(( (SCREEN_MAX_WIDTH * SCREEN_MAX_WIDTH) / 485 ))
    SAFETY_FACTOR=$(( ( ( quadraticWidthEmphasis * 82 ) / 100) + 44 ))  ## ei voi käyttää 0.82 arvoa, siksi näin
    ## Leveydellä 426 pitää olla 350 (82 %)! Leveydellä 100 taas 60 (60 %)! Tämä toteuttaa sen.
  fi

  widthOfbeginningPart=${#beginningPart}
  maxSize=$((SCREEN_MAX_WIDTH - SAFETY_FACTOR))
  spaceLeftForEndPart=$((maxSize - widthOfbeginningPart))
  [ $spaceLeftForEndPart -lt 0 ] && spaceLeftForEndPart=0
  
  if [ "$isGatherValuesForAutocomplete" == true ] && [ "$isCacheUsable" == false ] && \
     [ "$isNormalOutputRendered" == false ] && [ "$COLORFUL_AUTOCOMPLETE" == false ]; then
    local cbColor=""; local NO_COLOR=""; local textColor=""; MAGENTA="";
  fi

  widthOfFinalWithoutColor=${#finalPrintWithoutColor}
  if [[ $widthOfFinalWithoutColor -gt $maxSize ]]
    then local finalPrint="  ${cbColor}${checkbox}${NO_COLOR}  (${MAGENTA}${file}${NO_COLOR}) ${textColor}${endPart:0:$((spaceLeftForEndPart))} ...${NO_COLOR}"
    else local finalPrint="  ${cbColor}${checkbox}${NO_COLOR}  (${MAGENTA}${file}${NO_COLOR}) ${textColor}${text}${NO_COLOR}"
  fi

  if [ "$isGatherValuesForAutocomplete" == true ] && [ "$isCacheUsable" == false ]; then  ## jos cache ei kunnossa, täytetään se
    TASKS_FOR_AUTOCOMPLETE+=( "$finalPrint" )
  fi

  [ "$isNormalOutputRendered" == true ] && echo -e "$finalPrint"
}

## -- Tärkein funktio! --
printMatching() {
  local -a tasks
  local regexp="$1"
  local checkbox="$2"
  local offset="$3"
  [ -n "$4" ] && local cbColor="$4"   || cbColor="$NO_COLOR"
  [ -n "$5" ] && local textColor="$5" || textColor="$cbColor"
  
  shopt -s lastpipe  ## Tämä vaaditaan tai muuten muutos näkyisi vain alishellissä (jonka pipe luo ja) joka exittaa
  grep -rEn --color=never --regexp="$regexp" $SEARCH_PATH | while read -r task; do
      tasks+=( "$task" )
  done


  for task in "${tasks[@]}"; do
    local taskText; taskText="$(echo $task | cut -d : -f 3-)"
    
    if    [ "$isGatherValuesForAutocomplete" == false ] && [ "$displayFilePath" == false ]; then  ## default
      file="$(echo $task | cut -d : -f 1 | xargs -L 1 basename)"
    elif  [ "$isGatherValuesForAutocomplete" == false ] && [ "$displayFilePath" == true ]; then
      file="$(echo $task | cut -d : -f 1)"
    elif  [ "$isGatherValuesForAutocomplete" == true ]; then
      file="$(echo $task | cut -d : -f 1 | xargs -L 1 basename)"
    fi
    local text="${taskText:$((2+offset))}"

    [ "$isCacheUsable" == true ] && [ "$isNormalOutputRendered" == false ] && break  ## TODO: Tarkista joskus onko tämä validi paikka tälle

    printWithinScreenWithColors

    if [ "$isCacheUsable" == false ]; then
      local lineNumber; lineNumber="$(echo $task | cut -d : -f 2)"
      local fileToCache; fileToCache="$(echo $task | cut -d : -f 1)"
      fileToCache="$fileToCache:$lineNumber"
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
      [[ "$(find "$AUTOCOMPLETE_CACHE_FILE" -newermt "-$CACHE_VALID_MAX_SECONDS seconds" -print)" ]]; then
        isCacheUsable=true
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
  local index="$(($indexToEditZsh - 1))"  ## zsh indeksointi alkaa 1:stä eikä 0:sta
  local size="${#FILES_FOR_AUTOCOMPLETE[@]}"
  [ "$index" -ge $size ] && fail "Annettu indeksi on liian suuri!"
  [ "$index" -lt 0 ] && fail "Annettu indeksi ei voi olla alle yhden!"
  
  local fileWithRow="${FILES_FOR_AUTOCOMPLETE[$index]}"
  local komento=""
  
  if [ "$EDITOR_IS_SUBL" == true ] && command -v /bin/subl &> /dev/null; then
    komento="subl $fileWithRow"
  else
    local row;  row="$(echo $fileWithRow | cut -d : -f 2)"
    local file; file="$(echo $fileWithRow | cut -d : -f 1)"
    komento="nano -l +$row $file"
  fi
  
  echo "$komento"
  $komento
  return 0  ## Palautetaan onnistunut suoritus vaikka komento feilaisikin (esim. editori ei asennettuna)
}


## ---- Optionit eli tässä tapauksessa vivut ym esiehdot ----
for arg in "$@"; do  ## Hjälp on short-circuiting eli voi laittaa mihin vaan ja luottaa että vain tulostaa helpin
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp && exit 0
done

showPriority=true
showNormal=true
showIgnored=false
showCompleted=true
displayFilePath=false
isNormalOutputRendered=true
isEditNotes=false
isGatherValuesForAutocomplete=false
isCacheUsable=false
for arg in "$@"; do
  if    [ "$arg"  == "path" ]; then
    showIgnored=true
    displayFilePath=true
  elif  [ "$arg" == "all" ]; then
    showIgnored=true
  elif  [ "$arg" == "ignored" ]; then
    showIgnored=true
    showPriority=false
    showNormal=false
    showCompleted=false
  elif  [ "$arg" == "undone" ]; then
    showCompleted=false
  elif  [ "$arg" == "priority" ]; then
    showNormal=false
    showCompleted=false
  elif  [ "$arg" == "add" ]; then
    if [ -z "$3" ];
      then addMe "$2" "todo/todo.txt"
      else addMe "$2" "$3"
    fi
    break;
  elif  [ "$arg" == "edit" ] || [ "$arg" == "autocomplete_edit" ]; then  ## autocomplete_edit on piilotettu vipu
    setIsCacheUsableOrClear
    isNormalOutputRendered=false
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

NO_COLOR='\033[0;37m'
NORMAL_CB='\033[1;90m'
DONE_BOX='\033[1;92m'
RED='\033[0;31m'
MAGENTA='\033[0;95m'
PRIORITY='\033[1;37m'
IGNORE_CB='\033[2;90m'
IGNORE='\033[2;97m'
DONE_TEXT='\033[0;92m'

## ---- Ohjelmalogiikka -----
[ "$isNormalOutputRendered" == true ] && echo -e "Tämänhetkiset täskit"

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
[ "$showPriority" == true ] && \
  printMatching "$start§{2}$end"  "[ ]"   1   "$PRIORITY"

## tekemättömät
[ "$showNormal" == true ] && \
  printMatching "$start§{1}$end"  "[ ]"   0   "$NORMAL_CB"  "$NO_COLOR"

## ignore
[ "$showIgnored" == true ] && \
  printMatching "${start}_§$end"  "[ ]"   1   "$IGNORE_CB"  "$IGNORE"

## tehdyt
[ "$showCompleted" == true ] && \
  printMatching "$start!§$end"    "[x]"   1   "$DONE_BOX"   "$DONE_TEXT"

## vanhat väärät
  printMatching "$start§!$end"    "Virheellinen merkintä! Katso --help"    1   "$RED"

[ "$isCacheUsable" == false ] && writeToCache
[ "$isEditNotes" == true ] && editNote && exit 0
[ "$isGatherValuesForAutocomplete" == true ] && displayResultsForAutocomplete
