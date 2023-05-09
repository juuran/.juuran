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

for arg in "$@"; do
  [[ $arg == "parallel" ]] || [[ $arg == "paral" ]] && parallel="true"
  [[ $arg == "fetch" ]] && onlyFetch="true" && echo -e "Performing 'fetch --all --prune' on all projects."
  [[ $arg == "do" ]] && doToAll="$2" && runCustomCommand="true" && onlyFetch="false"
done

## Tämä saattaa olla vielä väärin...
[[ $runCustomCommand == "false" ]] && [[ $parallel == "false" ]] && [[ $onlyFetch == "false" ]] && [[ -z $doToAll ]] && [[ -n $1 ]] && \
  echo "Unrecognized option!" && exit 1

[[ $parallel == "true" ]] && [[ $runCustomCommand == "true" ]] && echo "Parallel running is not allowed with option 'do' because it \
skews the logs and could do damage to all projects with unsafe parameters." && exit 2

runGitCommand() {
  [[ $parallel == "true" ]] && echo "Working on $shortPath." || echo -e "\nWorking on $shortPath. "

  if [[ $onlyFetch == "true" ]]; then
    echo "Fetching all projects."
    git -C "$fullPath" fetch --all --prune || exit 2
  elif [[ $runCustomCommand == "true" ]]; then
    echo "Running command: git -C $fullPath $doToAll"
    git -C "$fullPath" $doToAll || exit 2   ## Ei toimi jos "$doToAll", vain noin. Veikkaan että yrittäisi antaa silloin tarjota esim. git "branch --show-current" kun git taas osaa lukea vain git "branch" "--show-current". Mene ja tiedä!
  
  else
  ## Run git pull
    local currentBranch
    currentBranch=$(git -C "$fullPath" branch --show-current)
    git -C "$fullPath" checkout $branch && \
    git -C "$fullPath" pull && \
    git -C "$fullPath" checkout $currentBranch \
    || exit 2
  fi
}


projects=$(find . -mindepth 1 -maxdepth 1 -type d)
for path in $projects; do
  shortPath="${path:2}"
  fullPath="$(pwd)/$shortPath"
  branch="develop"
  
  ## poikkeukset polkujen suhteen, esim eri oletushaara
  [[ $shortPath == "cpi-token-test" ]] && branch="master" && echo -en "\nSetting default branch as 'master' for cpi-token-test."
  [[ $shortPath == "EESSITestingki" ]] && echo -e "\nSkipping '$shortPath'." && continue ## intellij kansioni
  [[ $shortPath == "yms" ]] && echo -e "\nSkipping '$shortPath'." && continue  ## muut kokeilut

  if [[ $parallel == "true" ]]; then
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
      echo -e "\nProcess $p exited with nonzero exit code"
      failures=$((failures+1))
    fi
done

if [[ $failures -gt 0 ]]; then
    echo "Out of all the projects, $failures failed. Exiting with error. Run without parallel processing to get clearer logs!"
    exit 1
  else
    [[ $runCustomCommand == "true" ]] || [[ $onlyFetch ]] && echo -e "\nAll projects processed successfully!" || \
    echo -e "\nAll projects were pulled successfully!"  
    exit
fi
