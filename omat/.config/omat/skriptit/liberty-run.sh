#!/bin/bash
source "$(dirname "$0")/fail.sh"

handleSignals() {
    echo -e "\n$(basename "$0") lopetettu"
    exit 1
}

trap 'handleSignals' SIGINT
trap 'handleSignals' SIGQUIT

## vähän ruma fixi, kun aiemmassa oli hupsu oletus pää ja ear polun yhdennimisyydestä
# "${PWD##*/}-ear"
earPaths="$(ls -d */ | grep -ear | cut -d / -f 1)"

earPathFound=false
for path in $earPaths; do
    [ -d "$path" ] && earPathFound=true
done

if ! [ -f "./pom.xml" ] || [ $earPathFound == false ]; then
    fail "Both pom.xml and -ear subdirectories are needed, condition not met"
fi

[ -n "$1" ] && [[ "$1" != *-* ]] && echo "(argumentti ohitettu, koska skripti ei käytä niitä)"

## defaultit
isSkipTests=false
isBuild=false
isDontRunLiberty=false
while getopts "sbcn" OPTION; do
    case "$OPTION" in
    s)
        isSkipTests=true
        ;;
    b)
        isBuild=true
        clean=""
        puhdas=""
        ;;
    c)
        isBuild=true
        clean="clean"
        puhdas="puhdas "
        ;;
    n)
        isDontRunLiberty=true
        ;;
    *)
        fail "vain seuraavia vipuja tuetaan: \n-s (skippaa testit)\n-c (clean build)\n-n (no liberty be run)"
        ;;
    esac
done
shift "$(($OPTIND -1))"

if [ "$isBuild" == true ]; then
    if [ "$isSkipTests" == true ]
        then
            echo "tehdään ${puhdas}buildi ilman testejä..."
            mvn -e $clean install -DskipTests || fail "\nmaven build epäonnistui!"
        else 
            echo "tehdään ${puhdas}buildi..."
            mvn -e $clean install || fail "\nmaven build epäonnistui!"
    fi
    echo -e "maven build onnistui!\n"
fi

[ "$isDontRunLiberty" == true ] && exit 0

echo -e "käynnistetään open liberty...\n" && sleep 0.5
mvn -pl "$earPath" -e -P local liberty:run
