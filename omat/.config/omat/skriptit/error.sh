#!/bin/bash

## Elämää helpottava skripti numero uno. Tulostaa annetun viestin -> syserr.
##    1. argumentti on viesti - jos alkaa rivinvaihdolla, niin se syötetään ennen skriptin nimeä, ei tue yli yhtä rivinvaihtoa viestin alussa
function error() {
    [ -z "$*" ] && return
    if [[ "$*" == "\n\n"* ]]; then
        echo "virhe kutsussa!!! error (tai fail) komennot eivät tue kahta rivinvaihtoa viestin alussa!"
        exit 99
    elif [[ "$*" == "\n"* ]]; then
        kaikki="$*"  ## oma muutttuja, että voidaan pätkäistä \n merkki alusta pois ettei tule tuplana
        >&2 echo -e "\n$(basename "$0"): ${kaikki:2}"
    else 
        >&2 echo -e "$(basename "$0"): $*"
    fi
}
