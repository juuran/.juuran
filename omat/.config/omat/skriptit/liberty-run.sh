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
earPath="$(ls -d */ | grep *-ear | cut -d / -f 1)"

if ! [ -f "./pom.xml" ] || ! [ -d "$earPath" ]; then
    fail "Both pom.xml and -ear subdirectories are needed, condition not met"
fi

[ -n "$1" ] && [[ "$1" != *-* ]] && echo "(argumentti ohitettu, koska skripti ei käytä niitä)"

while getopts "sc" OPTION; do
    case "$OPTION" in
    s)
        isSkipTests=true
        ;;
    c)
        isCleanBuild=true
        ;;
    *)
        fail "vain seuraavia vipuja tuetaan: \n-s (skippaa testit)\n-c (clean build)"
        ;;
    esac
done
shift "$(($OPTIND -1))"

if [ "$isCleanBuild" == true ]; then
    if [ "$isSkipTests" == true ]
        then
            echo "tehdään puhdas build ilman testejä..."
            mvn -e clean install -DskipTests || fail "\nmaven build epäonnistui!"
        else 
            echo "tehdään puhdas build..."
            mvn -e clean install || fail "\nmaven build epäonnistui!"
    fi
    echo -e "maven build onnistui!\n"
fi

echo -e "käynnistetään open liberty...\n" && sleep 0.5
mvn -pl "$earPath" -e -P local liberty:run
