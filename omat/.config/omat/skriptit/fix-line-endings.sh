#!/bin/bash

source "$(dirname "$0")/fail.sh"

fixLineEndings() {
    local path="$1"

    ## Alempi järkyttävä litania, koska find normaalisti erottelee tulokset oudosti, ja bash ei sitä oletuksena jummara.
    readarray -d '' fileNames < <(find "$path" -type f -iname "**" -print0)
    for file in "${fileNames[@]}"; do
        ## Convert only files that have DOS line breaks and leave the other files untouched:
        dos2unix $file
    done

    echo "Poistetaan mahdollisesti luodut temppfilut (jos win kirjoitussuojatun tiedoston korjaus ei ole onnistunut)."
    readarray -d '' filesToDelete < <(find "$path" -type f -iname "d2utmp*" -print0)
    for fileToDelete in "${filesToDelete[@]}"; do
        if [[ "$fileToDelete" == *.* ]]; then
            fail "Tiedostonimi $fileToDelete ei ole päätteetön, joten en uskalla poistaa!"
        fi
        rm "$fileToDelete"
        echo "Poistettu $fileToDelete"
    done
}

if [ -n "$1" ];
    then fixLineEndings "$1"
    else fixLineEndings "$HOME/notes/"
fi
