#!/bin/bash

source "$(dirname "$0")/fail.sh"

## Tukee vain yhtä porttia
if [ -n "$1" ];
    then [ "$1" -eq $(($1)) ] || fail "annetun portin pitää olla numero!"
         PORT=$1
    else PORT=6996
fi

echo -e "aloitetaan echo server paikallisesti portissa $PORT..."
echo -e "(mikäli portti on käytössä tai tulee muu virhe, paina ENTER lopettaaksesi)\n"

# Start the server and listen for incoming connections
while true; do
  (echo -ne "HTTP/1.1 200 OK\r\n"; cat) \
    | nc -l -p $PORT \
    || fail "porttinumero ei ole sallittu."
done
