#!/bin/bash
source "$(dirname "$0")/fail.sh"

handleSignals() {
    echo -e "\nkeskeytetään open libertyn käynnistys..."
    exit 1
}

trap 'handleSignals' SIGINT
trap 'handleSignals' SIGQUIT

if ! [ -f "./pom.xml" ] || ! [ -d "./${PWD##*/}-ear" ]; then
    fail "No pom.xml or -ear subdirectory found"
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
            mvn clean install -DskipTests || fail "\nmaven build epäonnistui!"
        else 
            echo "tehdään puhdas build..."
            mvn clean install || fail "\nmaven build epäonnistui!"
    fi
    echo -e "maven build onnistui!\n"
fi

echo -e "käynnistetään open liberty...\n" && sleep 0.5
mvn -pl "${PWD##*/}-ear" -e -P local liberty:run
