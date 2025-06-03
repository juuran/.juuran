#!/bin/bash

source "$SKRIPTIT_POLKU/error.sh"

## Elämää helpottava skripti, joka printtaa virheen syserr:iin ja poistuu virhekoodilla.
##   1. argumentti on viesti
##   2. argumentti on vapaaehtoinen exit koodi, oletuksena 1
function fail() {
    error "$1"
    exitCode=1
    [ -n "$2" ] && exitCode=$2
    exit $exitCode
}
