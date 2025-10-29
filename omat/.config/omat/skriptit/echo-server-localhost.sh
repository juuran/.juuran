#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

handleSigInt() {
    echo -e "\n$(basename "$0") lopetettu"
    exit 1
}

handleSigQuit() {
    echo -n "katkaistaan kutsujan yhteys... "
    RUNNING=false
}

TIMEOUT=10
VERSIO=v1
RUNNING=true

echoserve() {
    trap 'handleSigInt' SIGINT
    trap 'handleSigQuit' SIGQUIT

    local port

    if [ -n "$1" ]; then
        [ "$1" -eq $(($1)) ] || fail "annetun portin pitää olla numero!"
        port=$1

    else
        port=6996

    fi

    for arg in "$@"; do
        if [ "${arg:0:1}" == "v" ]; then
            VERSIO="$arg"
        else
            TIMEOUT="$arg"
        fi
    done

    echo -e "aloitetaan echo server paikallisesti portissa $PORT..."
    echo -e "(mikäli portti on käytössä tai tulee muu virhe, paina ENTER lopettaaksesi, muutoin CTRL + C lopettaa)\n"

    ## Tämäpä ei olekaan niin helppo ongelma kuin voisi kuvitella! Älä käytä tähän enää aikaa, jooko?
    ## Toimii ekalle viestille, mutta sen jälkeen pitää käynnistää uudestaan. Thumbs down.
    if [ $VERSIO = "v1" ]; then
        (echo -ne "HTTP/1.1 200 OK\r\n\r\n"; cat) | nc -l -p $port -i 2 -w $TIMEOUT \
        || fail "nc heitti virheen."

    elif [ $VERSIO = "v2" ]; then
        (echo -ne "HTTP/1.1 200 OK\r\n\r\n"; cat) | nc -l -p $port -q 1 -w $TIMEOUT \
        || fail "nc heitti virheen."

    elif [ $VERSIO = "v3" ]; then
        echo -e "v3 on pysyväisesti päällä – asiakkaan yhteden voi katkaista SIGQUITilla, mikä oletuksena bindattu [ctrl + \\]\n"
        while true; do
            while [ $RUNNING = true ]; do
                (echo -e "HTTP/1.1 200 OK\r\n\r\n"; cat) | nc -l -p $port -q 1 -w 999999
            done
            echo -e "katkaistu. \n(Lopeta serveri SIGINTILLÄ [ctrl + c])\n"
            RUNNING=true
        done

    else
        fail "epätuettu versionumero"

    fi
}

echoserve "$@"
