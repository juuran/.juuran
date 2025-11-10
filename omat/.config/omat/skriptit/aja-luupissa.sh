#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

handleSigInt() {
    [ $RUNNING = false ] && fail "saatu pyyntö keskeyttää, lopetettu onnistuneesti" 0
    echo -n "keskeytetään ajossa oleva kutsu... "
    RUNNING=false
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
    echo -e "\naloitetaan ajamaan luupissa: $komento\n"

    while true; do
        while [ $RUNNING = true ]; do
            $komento
        done
        echo -e "keskeytetty, mutta kännistetään pian uudelleen. \n(lopeta serveri toisella SIGINTILLÄ [ctrl + c])\n\n\n"
        sleep 1

        RUNNING=true
    done
}

ajaLuupissa "$@"
