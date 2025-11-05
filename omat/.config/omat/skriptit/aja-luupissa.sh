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

    echo "-- yksi SIGINT        keskeyttää ajossa olevan komennon --"
    echo "-- kaksi SIGINTIÄ     lopettaa tämän skriptin"
    sleep 1
    echo -e "\naloitetaan ajamaan luupissa: $komento\n"

    while true; do
        while [ $RUNNING = true ]; do
            $komento
        done
        echo -e "keskeytetty, mutta kännistetään pian uudelleen. \n(lopeta serveri toisella SIGINTILLÄ [ctrl + c])\n"
        sleep 1

        RUNNING=true
    done
}

ajaLuupissa "$@"
