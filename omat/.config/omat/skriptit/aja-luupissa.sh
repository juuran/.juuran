#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

handleSigInt() {
    if [ $RUNNING = false ]; then
        echo ""
        echo "[ aja-luupissa skripti lopetettu onnistuneesti ]"
        echo ""
        exit 0
    else
        RUNNING=false
    fi
}

RUNNING=true

ajaLuupissa() {
    local komento="$*"

    [ -z "$komento" ] && fail 'argumentti vaaditaan, esim. "echo moi && sleep 1"'
    trap 'handleSigInt' SIGINT
    trap 'handleSigQuit' SIGQUIT

    echo "+-------------------------------------------------------------+"
    echo "|                                                             |"
    echo "|   [            Aja komentoa luupissa v. 1.1             ]   |"
    echo "|    - yksi SIGINT:      restarttaa ajossa olevan komennon    |"
    echo "|    - kaksi SIGINTIÄ:   lopettaa komennon ja skriptin        |"
    echo "|                                                             |"
    echo "+-------------------------------------------------------------+"

    sleep 1

    while true; do
        while [ $RUNNING = true ]; do
            echo ""
            echo "[ aloitetaan ajamaan luupissa: '$komento' ]"
            echo ""
            $komento
        done

        echo ""
        echo "+---------------------------------------------------------+"
        echo "|                                                         |"
        echo "|   komento keskeytetty, käynnistetään pian uudelleen...  |"
        echo "|   lopeta serveri toisella SIGINTILLÄ: [ctrl + c]        |"
        echo "|                                                         |"
        echo "+---------------------------------------------------------+"
        sleep 1

        RUNNING=true
    done
}

ajaLuupissa "$@"
