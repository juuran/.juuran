#!/bin/bash

## Kopioitu ja parannettu Kelan templates reposta: 
## https://bitbucket-alm.kela.fi/projects/TEMPLATES/repos/misc/browse/

source "$SKRIPTIT_POLKU/fail.sh"

function failAndDelete() {
    local file errorText errorCode
    file="$1"; errorText="$2"; errorCode="$3";
    rm "$file"
    fail "$errorText" "$errorCode"
}

printHelp() {
    echo ""
    echo "oc-seal.sh - seals openshift secrets (v. 1.02)"
    echo ""
    echo "Usage:"
    echo "  oc-seal [SECRET]...       seal one or more (unsealed) secrets as sealed secrets to be added to git"
    echo "Options:"
    echo "  -h, --help                prints this help"
    echo ""
    exit 0
}

for arg in "$@"; do
    [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp && exit
done

noOfArgs=$#
[ $noOfArgs -lt 1 ] && printHelp && fail "No secrets given! See help above for instructions."


function main() {
    #if kubeseal not found exit
    ks=$(kubeseal --version)
    echo $ks
    [[ $ks != *"version:"* ]] && fail "-- kubeseal CLI not found --"

    #if oc client not found exit
    ocli=$(oc version)
    echo $ocli
    [[ $ocli != *"Version:"* ]] && fail "--OC Client not found --"

    echo "---------------------------"
    echo "-- Sealed Secrets Script --"
    echo "---------------------------"

    ## Nykyään osaan kuvitella mitä varakopioilla tekisin, mutta lisättävä .gitignoreen
    echo "Check if backup dir for Secrets already exists..."
    DIR_BACKUP="secrets_backup"
    if [ -d "$DIR_BACKUP" ]; then
        echo "Backup dir ${DIR_BACKUP} already exists"
        else
        echo "Backup dir doesn't exists - creating dir ${DIR_BACKUP}"
        mkdir secrets_backup
    fi

    i=1;
    for s in "$@"
    do
        echo "Secret - $i: $s";
        sealedFile="sealed-$s.yaml";
        secretYaml=$(oc get secrets $s -o yaml) || fail "Could not find secret, exiting with error..." 2
        echo "$secretYaml" \
            | kubeseal --controller-namespace sealed-secrets -o yaml --scope namespace-wide > $sealedFile \
            || failAndDelete "$sealedFile" "Could not produce a sealed secret file, exiting with error..." 2
        echo "Sealed Secret file created - $i: $sealedFile";
        oc get secret $s -o yaml > $DIR_BACKUP/$s.yaml

        echo "Deleting unsealed Secret from namespace:"
        oc delete secrets $s \
            || error "could not delete secret $s from openshift, continuing nevertheless..."
        #oc apply -f $sealedFile;  ## miksi tehtäisiin näin, kun kerran versionhallinnan kautta viedään?!

        echo "Deleting the unsealed secret file locally (if it exists)"
        rm -Iv $s || rm -Iv $s.y*ml \
            || echo "The secret file did not exist (or did not share the same exact name), continuing"
        i=$((i + 1));
    done

    echo "---------------------------"
    echo "--  Secrets are sealed   --"
    echo "---------------------------"
}

main "$*"
