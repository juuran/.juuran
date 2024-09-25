#!/bin/bash
source "$(dirname "$0")/fail.sh"

printHelp() {
    echo "vain seuraavia vipuja tuetaan:"
    echo "-s(kippaa testit)"
    echo "-c(lean build)"
    echo "-n(o liberty will be run)"
    echo "-d(ev)"
}

handleSignals() {
    echo -e "\n$(basename "$0") lopetettu"
    exit 1
}

## optioiden käsittely
for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp && exit
done

isSkipTests=false
isBuild=false
isDontRunLiberty=false
mode="run"
clean=""
puhdas=""
while getopts "sbcdn" OPTION; do
    case "$OPTION" in
    s)
        isSkipTests=true
        ;;
    b)
        isBuild=true
        ;;
    c)
        isBuild=true
        clean="clean"
        puhdas="puhdas "
        ;;
    d)
        mode="dev"
        ;;
    n)
        isDontRunLiberty=true
        ;;
    *)
        printHelp
        fail "ei tuettu vipu"
        ;;
    esac
done
shift "$(($OPTIND -1))"


main() {
    trap 'handleSignals' SIGINT
    trap 'handleSignals' SIGQUIT

    ## vähän ruma fixi, kun aiemmassa oli hupsu oletus pää ja ear polun yhdennimisyydestä
    # "${PWD##*/}-ear"
    earPaths="$(ls -d */ | grep "\-ear" | cut -d / -f 1)"

    earPathFound=false
    for path in $earPaths; do
        if [ -d "$path" ]; then
            earPathFound=true
            earPath="$path"
        fi
    done

    if ! [ -f "./pom.xml" ] || [ $earPathFound == false ]; then
        fail "Both pom.xml and -ear subdirectories are needed, condition not met"
    fi

    echo "päätelty, että earin polku on: $earPath"

    [ -n "$1" ] && [[ "$1" != *-* ]] && echo "(argumentti ohitettu, koska skripti ei käytä niitä)"

    if [ "$isBuild" == true ]; then
        if [ "$isSkipTests" == true ]
            then
                echo "tehdään ${puhdas}buildi ilman testejä..."
                echo "(    suoritetaan:   mvn -e $clean install -DskipTests    )"
                mvn -e $clean install -DskipTests || fail "\nmaven build epäonnistui!"
            else 
                echo "tehdään ${puhdas}buildi..."
                echo "(    suoritetaan:   mvn -e $clean install    )"
                mvn -e $clean install || fail "\nmaven build epäonnistui!"
        fi
        echo -e "maven build onnistui!"
    fi

    [ "$isDontRunLiberty" == true ] && exit 0

    echo -e "\nkäynnistetään open liberty..."
    echo "(    suoritetaan:   mvn -pl "$earPath" -e -P local liberty:$mode    )"
    sleep 0.5
    mvn -pl "$earPath" -e -P local liberty:$mode
}

main "$@"  ## antaa vain "jäljellä olevat" argumentit eli optioissa käsitellyt jo poistettu
