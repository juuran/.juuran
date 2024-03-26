#!/bin/bash
source "$(dirname "$0")/fail.sh"

printHelp() {
  echo "        color-me-logs.sh - log colorizer (v.1.02)"
  echo "Adds a little sparkle to your day!"
  echo
  echo "Usage example:"
  echo "    cat log | color-me-logs       Used typically as part of a pipe."
  echo "    color-me-logs                 Called alone is waiting in an endless grep loop."
  echo
  echo "Options:"
  echo "    -h, --help  (switch)          Prints this help."
  echo "    -m          (nees argument)   Mode to select how log level (INFO, ERROR, etc.) is interpreted. Selections: default, holodeck, typical."
  echo
  exit 0
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp  ## Short-circuiting eli -h tai --help voi laittaa mihin vain ja aina quittaa!
done

mode="default"
## Optioiden käsittely
while getopts "m:h" OPTION; do
  case "$OPTION" in
    m)
      if   [ "$OPTARG" == "default" ];  then mode="default"
      elif [ "$OPTARG" == "holodeck" ]; then mode="holodeck"
      elif [ "$OPTARG" == "typical" ];  then mode="typical"
      elif [ "$OPTARG" == "liberty" ];  then mode="liberty"
      else fail "Unkown mode '$OPTARG'!"
      fi
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

d="[/\.\-]" ## date delimiter
t="[\.:]"   ## time delimiter
timeStamp="[0-9]{1,2}${d}[0-9]{1,2}${d}[0-9]{4} [0-9]{1,2}${t}[0-9]{1,2}${t}[0-9]{1,2}${t}[0-9]{0,6}"

## default
  INFO=" INFO "
DEBUG=" DEBUG "
TRACE=" TRACE "
  WARN=" WARN "
ERROR=" ERROR "
FATAL=" FATAL "

if [ "$mode" == "holodeck" ]; then
   INFO="\[INFO \]"
  DEBUG="\[DEBUG\]"
  TRACE="\[TRACE\]"
   WARN="\[WARN \]"
  ERROR="\[ERROR\]"
  FATAL="\[FATAL\]"
elif [ "$mode" == "typical" ]; then
   INFO="\[ INFO \]"
  DEBUG="\[ DEBUG \]"
  TRACE="\[ TRACE \]"
   WARN="\[ WARN \]"
  ERROR="\[ ERROR \]"
  FATAL="\[ FATAL \]"  ## värien takia näin
elif [ "$mode" == "liberty" ]; then
  # libertyssä timestamp näyttää tältä: [3/26/24, 13:44:56:815 EET]
  timeStamp="\[[0-9]{1,2}${d}[0-9]{1,2}${d}[0-9]{2}, [0-9]{1,2}${t}[0-9]{1,2}${t}[0-9]{1,2}${t}[0-9]{0,6} EET\]"
fi

      ##                              VÄRIT JA EFEKTIT
      ## -----------------------------------------------------------------------------------
      ## mt     matching text in matching line            30 Black    0 Reset all attributes
      ## ms     matching text in selected line            31 Red      1 Bright
      ## mc     matching text in context line             32 Green    2 Dim
      ## sl     selected line                             33 Yellow   4 Underscore
      ## se     separators inserted between sl fields     34 Blue     5 Blink
      ## cx     context line ???                          35 Magenta  7 Reverse
      ## fn     file names prefixing any content line     36 Cyan     8 Hidden
      ## ln     line numbers                              37 White
      ##

  GREP_COLORS="mt=0;36" grep --line-buffered --color=always -a -E -e "$timeStamp" -e "**" \
| GREP_COLORS="mt=1;32" grep --line-buffered --color=always -a -E -e "$INFO"  -e "**" \
| GREP_COLORS="mt=2;32" grep --line-buffered --color=always -a -E -e "$DEBUG" -e "**" \
| GREP_COLORS="mt=2;36" grep --line-buffered --color=always -a -E -e "$TRACE" -e "**" \
| GREP_COLORS="mt=1;33" grep --line-buffered --color=always -a -E -e "$WARN"  -e "**" \
| GREP_COLORS="mt=1;31" grep --line-buffered --color=always -a -E -e "$ERROR" -e "**" \
| GREP_COLORS="mt=1;31" grep --line-buffered --color=always -a -E -e "$FATAL" -e "**"
