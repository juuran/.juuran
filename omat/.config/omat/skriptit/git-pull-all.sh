#!/bin/bash

## Pikku skripti vain helpottamaan jokaisen mikropalvelujen kanssa elävän elämää.
## ... etenkin, jos tykkää käyttä gittiä komentoriviltä bash shellillä. Hakee
## siis polusta yksi ylöspäin (vai onko se sitten alaspäin) kaikkien kansioiden
## develop haarat, ellei tuolla for-luupissa muuta aseteta.

source "$(dirname "$0")/fail.sh"

pids=""
failures=0
parallel="false"
onlyFetch="false"
runCustomCommand="false"
pathsToSkip=()
doToAll=""

function showHelp() {
  echo "git-pull-all.sh (v.1.00)"
  echo
  echo "USAGE"
  echo "    git-pull-all.sh"
  echo "    git-pull-all.sh [OPTION...]"
  echo
  echo "OPTIONS:"
  echo "    -p      parallel (switch)       Runs commands faster but doesn't produce clear logs."
  echo "    -f      fetch (switch)          Only fetches (using --all --prune) instead of also merging as with 'git pull'."
  echo "    -d      do (argument needed)    Used for custom commands. Put all in \"quotes\". Doesn't need to be git related."
  echo "    -s      skip (argument needed)  Skips the path(s) specified after this switch. If multiple, use \"quotes\"."
  exit 0
}

runGitCommand() {
  if      [ $parallel == true ];      then  echo "** Working on $shortPath **"
  elif [ $runCustomCommand == true ]; then  echo -e "** --->  Entering '$shortPath' **"
  else                                      echo -e "\n** Working on $shortPath **"
  fi

  if [ $onlyFetch == true ]; then
    git -C "$fullPath" fetch --all --prune || fail "The given git fetch command failed!" 2
  elif [ $runCustomCommand == true ]; then
    cd "$fullPath" || fail "Couldn't cd into subdir"
    $doToAll
    echo -e "** <---  Exiting '$shortPath' **\n\n"
    cd .. || fail "Couldn't cd out of subdir"
  
  else
  ## Run git pull (the default)
    local currentBranch
    currentBranch=$(git -C "$fullPath" branch --show-current)
    git -C "$fullPath" checkout $pullBranch && \
      git -C "$fullPath" pull \
      || fail "Either git pull or git checkout failed!" 2

    [ "$currentBranch" != "$pullBranch" ] && git -C "$fullPath" checkout $currentBranch || true  ## Tämä olikin erikoinen keissi... Ilman tuota viimeistä truea, kuvittelee ohjelman päättyneen virheeseen. Johtunee siitä että ajetaan  &  eli forkataan(?) ja test komento palauttaa false, joka sitten siirtyy viimeisenä suorituksena kys shellille(?).
  fi
}

for arg in "$@"; do
  [ "$arg" == "--help" ] && showHelp
done

## Optioiden käsittely
while getopts "pfd:s:h" OPTION; do
  case "$OPTION" in
    p)
      parallel="true"
      ;;
    f)
      onlyFetch="true"
      echo -e "** Performing 'fetch --all --prune' on all projects **"
      ;;
    d)
      doToAll="$OPTARG"
      runCustomCommand=true
      onlyFetch="false"
      [ -z "$doToAll" ] && fail "The argument to \"do\" was not given!" 1
      ;;
    s)
      for path in ${OPTARG[@]}; do
        pathsToSkip+=( $path )
      done
      [ -z "${pathsToSkip[*]}" ] && fail "The paths to skip was empty!" 1
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


main() {

  [ $parallel == true ] && [ $runCustomCommand == true ] && fail "Parallel running is not allowed with option 'do' because it skews the logs and could do damage to all projects with unsafe parameters." 1

  [ "$runCustomCommand" == true ] && echo "** Running command in all subdirectories: $doToAll **"

  projects=$(find . -mindepth 1 -maxdepth 1 -type d)
  pathsToSkip+=( "EESSITestingki" "yms" "salt" )  ## skipataan aina vähintään nämä!
  for path in $projects; do
    shortPath="${path:2}"
    fullPath="$(pwd)/$shortPath"
    pullBranch="develop"
    isSkipped=false
    
    ## Skipattavat kansiot
    if [ -n "${pathsToSkip[*]}" ]; then  ## Tässä tähti teknisesti oikeampi kuin miukumauku, koska antaa yhtenä stringinä ulos
      for skipped in "${pathsToSkip[@]}"; do
        [ "$shortPath" == "$skipped" ] && echo -e "\n** Skipping '$skipped' **" && isSkipped=true && break ## -s(kip) vivulla skipataan
      done
    fi

    [ "$isSkipped" == true ] && continue
    
    ## Muut erikoistapaukset
    [ "$shortPath" == "cpi-token-test" ] && pullBranch="master" && echo -e "\n** Setting default branch as 'master' for cpi-token-test **"

    if [ "$parallel" == true ]; then
        runGitCommand &
      else
        runGitCommand
    fi
    
    pids+=" $!"           ## $! on viimeisimmän uuden taustaprosessin pid (olettaisin että tajuaa hakea vain kys. bash istunnon pidejä...?)
  done


  ## odotetaan että kaikki meni maaliin
  for p in $pids; do
      if wait $p; then true
      else
        echo -e "\n** Process $p exited with nonzero exit code **"
        failures=$((failures+1))
      fi
  done

  if [ $failures -gt 0 ]; then
      fail "** Out of all the projects, $failures failed. Exiting with error. Run without parallel processing to get clearer logs! **" 1
    else
      [ $runCustomCommand == true ] || [ $onlyFetch == true ] && echo -e "\n** All projects processed successfully! **" || \
      echo -e "\n** All projects were pulled successfully! **"  
  fi

}

main
