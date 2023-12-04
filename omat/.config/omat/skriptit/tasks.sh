#!/bin/bash
## Ai että. Kyllä siitä aika kaunis tuli vaikka itse sanonkin! Kyllähän tähän enemmän aikaa
## paloi, kuin oli alunperin tarkoitus... Mutta nyt ainakin toimii listaus kaikista tiedostoista
## ilman mitään häslinkiä ja voi luottaa, ettei ole duplikaatteja! Opinpahan reg expistä taas
## lisää sitä paitsi. Kyllä siinä pärjää ihan hyvin ilman capture groupejakin.

source "$(dirname "$0")/fail.sh"

clearCache() {
  echo -n "" > "$TASKS_CACHE"
}

[ -z $NOTES_PATH ] && NOTES_PATH="/home/c945fvc/notes"
SEARCH_PATH="$NOTES_PATH/*"
NO_COLOR='\033[0m'
GREEN=$(tput setaf 83)
RED='\033[0;91m'  
MAGENTA=$(tput setaf 134)
PRIORITY='\033[1;97m'
IGNORE='\033[2;97m'
DONE=$(tput setaf 71)
SCREEN_MAX_WIDTH=$(tput cols)
SAFETY_FACTOR=19   ## tämä on viimeinen arvo joka toimii sekä "path" että ilman. Älä pliis käytä tähän enää sekuntiakaan!
TASKS=()
TASKS_CACHE="$HOME/.cache/.tasks_edit_cache"
! [ -e "$TASKS_CACHE" ] && clearCache  ## Tyhjää, mutta myös luo cachen

printHelp() {
  echo "        tasks.sh (v.1.01)"
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
  echo "  -h, --help  tulostaa tämän helpin"
  exit
}

addMe() {
  thingToAdd="$1"
  [[ "$thingToAdd" == *"§"* ]] || fail "Muista käyttää syntaksimerkintöjä (esim. §)! Mitään ei tallennettu."
  echo "$thingToAdd" >> "$NOTES_PATH/todo.txt"
}

## Hjälp
for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

showNormal=true
showIgnored=false
showCompleted=true
displayFilePath=false
isRendered=true
storeValuesForAutocomplete=false
shouldCacheBeFilled=false
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
  elif  [ "$arg" == "edit" ] || [ "$arg" == "autocomplete_edit" ]; then
    if [ "$(stat -c %s $TASKS_CACHE)" -ne 0 ] && \
       [[ $(find "$TASKS_CACHE" -not -newermt '-5 seconds' -print) ]]; then
      clearCache ## Jos file on epätyhjä ja vanhempi kuin 12 s, poistetaan
    fi
    isRendered=false
    storeValuesForAutocomplete=true
    
    ## Muokkaus koskee aina kaikkia!
    showNormal=true
    showIgnored=true
    showCompleted=true
    displayFilePath=false
  else
    fail "Vääränlainen vipu!"
  fi
done

printWithinScreen() {
  local line="$1"
  maxSize=$((SCREEN_MAX_WIDTH + SAFETY_FACTOR))
  [[ ${#line} -gt $maxSize ]] && \
    echo -e "${printLine:0:$((maxSize))} ...$NO_COLOR" || \
    echo -e "$printLine$NO_COLOR"
}

printMatching() {
  local regexp color checkbox offset textColor file
  local -a tasks
  regexp="$1"
  color="$2"
  checkbox="$3"
  offset="$4"
  [ -n "$5" ] && textColor="$5" || textColor="$NO_COLOR"
  
  shopt -s lastpipe  ## Tämä vaaditaan tai muuten muutos näkyisi vain alishellissä (jonka pipe luo ja) joka exittaa
  grep -rE -h --color=never --regexp="$regexp" $SEARCH_PATH | while read -r task; do
      tasks+=( "$task" )
  done


  for task in "${tasks[@]}"; do
    if [ "$displayFilePath" == "true" ]
      then  file=$(grep -lr "$task" $SEARCH_PATH)
      else  file=$(grep -lr "$task" $SEARCH_PATH | xargs -L 1 basename)
    fi
    text="${task:$((2+offset))}"
    printLine="  ${color}${checkbox}${NO_COLOR}  (${MAGENTA}${file}${NO_COLOR}) ${textColor}${text}"

    if    [ "$isRendered" == true ]; then
      printWithinScreen "$printLine"
    elif  [ "$shouldCacheBeFilled" == true ]; then
        TASKS+=( "$text" )
        echo "${TASKS[@]}" >> "$TASKS_CACHE"
    fi
  done
}

displayResultsForAutocomplete() {
  if [ "$storeValuesForAutocomplete" == true ]; then
    size="${#TASKS[@]}"
    for (( i=0 ; i < $size ; i++ )); do
      echo -e "${TASKS[i]}"
    done
  fi
}


[ "$isRendered" == true ] && echo -e "\nTämänhetkiset täskit"
start="^[^§_!]*"  ## rivin alussa ei saa syntaksimerkkejä ennen vars. sääntöä
end="[^§]*$"      ## pykälä ei saa esiintyä uudestaan vars. säännön jälkeen (käytetään arkistointiin = poistamiseen tuloksista)

[ "$storeValuesForAutocomplete" == true ] && [ "$(stat -c %s $TASKS_CACHE)" -eq 0 ] && \
  shouldCacheBeFilled=true  ## Jos cachetus päällä ja cache tyhjä, niin täytetään sitä

## Käytetään ohituskaistaa jos juuri cachetettu tulokset, että toimisi nopeammin!
if [ "$storeValuesForAutocomplete" == true ] && [ "$shouldCacheBeFilled" == false ]; then
  TASKS="$(cat $TASKS_CACHE)"  ## Tähän on hyvä päättää. Cachetus toimii, mutta pitää vielä lukea oikein sisään.
  displayResultsForAutocomplete
  exit 0
fi

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

[ "$storeValuesForAutocomplete" == true ] && displayResultsForAutocomplete
