#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

handleSignals() {
    echo -e "\n$(basename "$0") lopetettu"
    exit 1
}

echoserve() {
  trap 'handleSignals' SIGINT

  ## Tukee vain yhtä porttia
  if [ -n "$1" ];
      then [ "$1" -eq $(($1)) ] || fail "annetun portin pitää olla numero!"
          PORT=$1
      else PORT=6996
  fi

  echo -e "aloitetaan echo server paikallisesti portissa $PORT..."
  echo -e "(mikäli portti on käytössä tai tulee muu virhe, paina ENTER lopettaaksesi, muutoin CTRL + C lopettaa)\n"

  ## Tämäpä ei olekaan niin helppo ongelma kuin voisi kuvitella! Älä käytä tähän enää aikaa, jooko?
  ## Toimii ekalle viestille, mutta sen jälkeen pitää käynnistää uudestaan. Thumbs down.
  while true; do
    if [ $HOSTNAME = "dev047tools1.kela.fi" ]; then
      (echo -ne "HTTP/1.1 200 OK\r\n\r\n"; cat) | nc -l -p $PORT -w 2 -i 2 \
      || fail "porttinumero ei ole sallittu."
    
    else
      (echo -ne "HTTP/1.1 200 OK\r\n\r\n"; cat) | nc -l -p $PORT -q 1 -w 2 \
      || fail "porttinumero ei ole sallittu."

    fi
  done
}

port="$1"
echoserve "$port"
