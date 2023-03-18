#!/bin/bash

## HARJOITUS! EI TOIMINUT!

runGitPull() {
  sleep 1 && echo "mukamas git -C $fullDir checkout $branch" && \
  sleep 3 && echo "mukamas git -C $fullDir pull"
}

N=100

find . -mindepth 1 -maxdepth 1 -type d | \
  (
    while read -r dir
    do
      shortDir="${dir:2}"
      fullDir="$(pwd)/$shortDir"
      branch="develop"
      
      ## poikkeukset oletushaaran suhteen
      [[ $shortDir == "cpi-token-test" ]] && branch="master"

      echo -e "\nCurrently working on $dir"
      # (git -C $fullDir checkout $branch || exit 1) &
      # (git -C $fullDir pull || exit 1) &

      
      ## Testi ennen kuin alan ajelemaan!
      ((i=i%N)); ((i++==0)) && wait
      runGitPull &

    done
  ) && wait

sleep 0.5
echo "All branches updated succesfully!"