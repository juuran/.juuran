#!/bin/bash

## Kopioitu ja parannettu Kelan templates reposta: 
## https://bitbucket-alm.kela.fi/projects/TEMPLATES/repos/misc/browse/

source "$SKRIPTIT_POLKU/fail.sh"

printHelp() {
  echo ""
  echo "oc-seal.sh - seals openshift secrets"
  echo ""
  echo "Usage:"
  echo "  oc-seal [SECRET]...       seal one or more secrets as sealed secrets to be added to git"
  echo "Options:"
  echo "  -h, --help                prints this help"
  exit 0
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp && exit
done

noOfArgs=$#
[ $noOfArgs -lt 1 ] && printHelp && fail "No secrets given! See help above for instructions."


#if kubeseal not found exit
ks=$(kubeseal --version)
echo $ks
if [[ $ks != *"version:"* ]]; then
  fail "-- kubeseal CLI not found --"
fi

#if oc client not found exit
ocli=$(oc version)
echo $ocli
if [[ $ocli != *"Version:"* ]]; then
  fail "--OC Client not found --"
fi

echo "---------------------------"
echo "-- Sealed Secrets Script --"
echo "---------------------------"

## En osaa kuvitella mitä näillä tekisin...
# echo "Check if backup dir for Secrets already exists..."
# DIR_BACKUP="secrets_backup"
# if [ -d "$DIR_BACKUP" ]; then
#   echo "Backup dir ${DIR_BACKUP} already exists"
# else
#   echo "Backup dir doesn't exists - creating dir ${DIR_BACKUP}"
#   mkdir secrets_backup
# fi

i=1;
for s in "$@" 
do
    echo "Secret - $i: $s";
    sealed="sealed-$s.yaml";
    secretYaml=$(oc get secrets $s -o yaml) || fail "Could not find secret, exiting with error..." 2
    echo "$secretYaml" | kubeseal --controller-namespace sealed-secrets -o yaml --scope namespace-wide > $sealed \
      || fail "Could not produce a sealed secret file, exiting with error..." 2
    echo "Sealed Secret file created - $i: $sealed";
    # oc get secret $s -o yaml > $DIR_BACKUP/$s.yaml  ## ei ole tarpeen, kiitos!

    echo "Deleting Secret from namespace:"
    oc delete secrets $s || error "could not delete secret $s from openshift, continuing nevertheless..."
    #oc apply -f $sealed;  ## miksi tehtäisiin näin, kun kerran versionhallinnan kautta viedään?!

    echo "Deleting the secret file locally (if it exists)"
    rm -Iv $s || rm -Iv $s.y*ml || echo "The secret file did not exist (or did not share the same exact name), continuing"
    i=$((i + 1));
done

echo "---------------------------"
echo "--  Secrets are sealed   --"
echo "---------------------------"
