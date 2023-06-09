#!/bin/bash

## Pikku skripti vain helpottamaan jokaisen mikropalvelujen kanssa elävän elämää.
## ... etenkin, jos tykkää käyttä gittiä komentoriviltä bash shellillä. Hakee
## siis polusta yksi ylöspäin (vai onko se sitten alaspäin) kaikkien kansioiden
## develop haarat, ellei tuolla for-luupissa muuta aseteta.

pids=""
failures=0
parallel="false"
onlyFetch="false"
runCustomCommand="false"
doToAll=""
showHelp=false

for arg in "$@"; do
  [ "$arg" == "parallel" ] || [ "$arg" == "paral" ] && parallel="true"
  [ "$arg" == "fetch" ] && onlyFetch="true" && echo -e ":: Performing 'fetch --all --prune' on all projects ::"
  [ "$arg" == "do" ] && doToAll="$2" && runCustomCommand="true" && onlyFetch="false"
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && showHelp=true
done

## Tämä saattaa olla vielä väärin...
if [ $showHelp == true ]; then
  echo "Note! All switches are written without the option symbol: -"
  echo -e "\nValid switches are:"
  echo "    parallel  OR  paral   Enables parallel running of git commands, but doesn't produce clear logs."
  echo "    fetch                 For fetching (--all --prune), instead of also merging as with 'git pull'."
  echo "    do                    For custom commands. Start without 'git' and Write all params in "quotes"."
  exit
elif [ $runCustomCommand == false ] && [ $parallel == false ] && [ $onlyFetch == false ] && [ -z "$doToAll" ] && [ -n "$1" ]; then
  echo "Unrecognized option! Type -h or --help for help"
  exit 1
fi

[ $parallel == true ] && [ $runCustomCommand == true ] && echo "Parallel running is not allowed with option 'do' because it \
skews the logs and could do damage to all projects with unsafe parameters." && exit 2

runGitCommand() {
  [ $parallel == true ] && echo ":: Working on $shortPath ::" || echo -e "\n:: Working on $shortPath ::"

  if [ $onlyFetch == true ]; then
    git -C "$fullPath" fetch --all --prune || exit 2
  elif [ $runCustomCommand == true ]; then
    echo ":: Running command: git -C $fullPath $doToAll ::"
    git -C "$fullPath" $doToAll || exit 2   ## Ei toimi jos "$doToAll", vain noin. Veikkaan että yrittäisi antaa silloin tarjota esim. git "branch --show-current" kun git taas osaa lukea vain git "branch" "--show-current". Mene ja tiedä!
  
  else
  ## Run git pull (the default)
    local currentBranch
    currentBranch=$(git -C "$fullPath" branch --show-current)
    git -C "$fullPath" checkout $pullBranch && \
      git -C "$fullPath" pull \
      || exit 2

    [ "$currentBranch" != "$pullBranch" ] && git -C "$fullPath" checkout $currentBranch || true  ## Tämä olikin erikoinen keissi... Ilman tuota viimeistä truea, kuvittelee ohjelman päättyneen virheeseen. Johtunee siitä että ajetaan  &  eli forkataan(?) ja test komento palauttaa false, joka sitten siirtyy viimeisenä suorituksena kys shellille(?).
  fi
}


projects=$(find . -mindepth 1 -maxdepth 1 -type d)
for path in $projects; do
  shortPath="${path:2}"
  fullPath="$(pwd)/$shortPath"
  pullBranch="develop"
  
  ## poikkeukset polkujen suhteen, esim eri oletushaara
  [ $shortPath == "cpi-token-test" ] && pullBranch="master" && echo -e "\n:: Setting default branch as 'master' for cpi-token-test ::"
  [ $shortPath == "EESSITestingki" ] && echo -e "\n:: Skipping '$shortPath' ::" && continue ## intellij kansioni
  [ $shortPath == "yms" ] && echo -e "\n:: Skipping '$shortPath' ::" && continue  ## muut kokeilut
  [ $shortPath == "salt" ] && echo -e "\n:: Skipping '$shortPath' ::" && continue  ## saltstack on vähän poikkeus

  if [ $parallel == true ]; then
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
      echo -e "\n:: Process $p exited with nonzero exit code ::"
      failures=$((failures+1))
    fi
done

if [ $failures -gt 0 ]; then
    echo ":: Out of all the projects, $failures failed. Exiting with error. Run without parallel processing to get clearer logs! ::"
    exit 1
  else
    [ $runCustomCommand == true ] || [ $onlyFetch == true ] && echo -e "\n:: All projects processed successfully! ::" || \
    echo -e "\n:: All projects were pulled successfully! ::"  
    exit
fi
