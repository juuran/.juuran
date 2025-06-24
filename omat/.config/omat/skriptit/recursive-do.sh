#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

function showHelp() {
  echo ""
  echo "recursive-do (v.1.00)"
  echo
  echo "USAGE"
  echo '    recursive-do.sh [OPTION]... "[TASK]"    The task must be placed after options and wrapped in "quotes".'
  echo '                                            Note that the caller can access the immediate pwd with $shortPath'
  echo
  echo "OPTIONS:"
  echo "    -p      parallel (switch)               Runs commands faster but doesn't produce very readable logs."
  echo "    -s      skip (argument needed)          Skips path(s) specified after the switch. If multiple, use \"quotes\"."
  exit 0
}

function handleSignals() {
    echo -e "\n$(basename "$0") lopetettu"
    fail "" 1
}

## Globaalit muuttujat
THING_TO_DO=""
PARALLEL=false
PATHS_TO_SKIP=()

## Optioiden käsittely
for arg in "$@"; do
    [ "$arg" == "--help" ] && showHelp
done

while getopts "ps:h" OPTION; do
    case "$OPTION" in
    p)
    PARALLEL="true"
    ;;
    s)
    for path in ${OPTARG[@]}; do
        PATHS_TO_SKIP+=( $path )
    done
    [ -z "${PATHS_TO_SKIP[*]}" ] && fail "The paths to skip was empty!" 1
    ;;
    h)
    showHelp
    ;;
    *)
    ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
    fail "Incorrect option or argument to an option: '$OPTARG'. Type -h for help!" 1
    ;;
    esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"

THING_TO_DO="$1"

function doTheThing() {
    local path;
    path="$1"

    if [ $PARALLEL == true ]; then
        echo "** Working on $path **"
    else
        echo -e "\n\n** Working on $path **"
    fi

    echo -e "** --->  Entering '$path' **"
    cd "$path" || fail "Couldn't cd into subdir"
    local exitCode;

    ## suoritetaan itse tehtävä
    ( 
        ## Sallitaan ne muuttujat, mitä ei ole mainittu alla eli: "shortPath", "path"
        local paths; local pids; local isSkipped; local numberOfPaths; local failures; local optionalWarning; local PARALLEL; local PATHS_TO_SKIP;
        eval "$THING_TO_DO"
    )
    exitCode=$?

    echo -e "** <---  Exiting '$path' **"
    cd .. || fail "Couldn't cd out of subdir"
    return $exitCode
}

function main() {

    trap 'handleSignals' SIGINT
    trap 'handleSignals' SIGQUIT

    ## Tehdään näin, koska uikuttaa, jos esittelee ja assignaa samalla rivillä.
    local paths; local pids; local shortPath; local isSkipped; local numberOfPaths; local failures; local optionalWarning;
    numberOfPaths=0
    failures=0

    ## itse "rekursio" (yksitasoinen)
    paths=$(find . -mindepth 1 -maxdepth 1 -type d)
    for path in $paths; do
        
        shortPath="${path:2}"
        isSkipped=false
        numberOfPaths=$((numberOfPaths + 1))
    
        ## Skipattavat kansiot
        if [ -n "${PATHS_TO_SKIP[*]}" ]; then  ## tähti teknisesti oikeampi kuin miukumauku, koska antaa yhtenä stringinä ulos
            for skipped in "${PATHS_TO_SKIP[@]}"; do
                if [ "$shortPath" == "$skipped" ]; then
                    echo -e "\n** Skipping '$skipped' **"
                    isSkipped=true
                    break
                fi
            done
        fi

        [ "$isSkipped" == true ] && continue

        if [ "$PARALLEL" == true ]; then
            doTheThing "$shortPath" &
            pids+=" $!"  ## $! on viimeisimmän uuden taustaprosessin pid
        else
            if doTheThing "$shortPath"; then true
            else
                failures=$((failures + 1))
            fi
        fi

    done

    if [ $PARALLEL = true ]; then
        ## odotetaan että kaikki meni maaliin
        for p in $pids; do
            if wait "$p"; then true
            else
                echo -e "\n** Process $p exited with nonzero exit code **"
                failures=$((failures + 1))
            fi
        done

        optionalWarning="Run without parallel processing to get clearer logs! "
    fi

    if [ $failures -eq 0 ]; then
        echo -e "\n** All tasks in all paths ($numberOfPaths in total) completed successfully! **"
    else    
        echo -e "\n\n**Out of $numberOfPaths paths, $failures returned an exit code other than 0 (success). Exiting with error. $optionalWarning**"
        fail "" 2
    fi
}

main
