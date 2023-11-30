#!/bin/bash

## Elämää helpottava skripti numero uno. Tulostaa annetun viestin -> syserr.
##    1. argumentti on viesti
function error() {
  [ -z "$*" ] && return
  >&2 echo -e "$(basename "$0"): $*"
}
