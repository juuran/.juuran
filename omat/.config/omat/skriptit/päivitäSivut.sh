#!/bin/bash

## Skripti, jolla rpi eli photoprism valokuvaserveri päivittää internet sivunsa.
## Tälle ei tehdä aliasta tai muutakaan kikkailua, vain säilössä täällä repossa.

DIR="/home/ubuntu/photoprism/sivut"                               ## skriptit ym ei julkinen data
GITHUB_SIVUT="/home/ubuntu/github-sivut/juuran.github.io"         ## julkinen internet
GITHUB_KUVAT="/home/ubuntu/github-sivut/juuran.github.io/kuvat"   ## julkinen internet
GITHUB_HAAT="/home/ubuntu/github-sivut/juuran.github.io/haat"     ## julkinen internet
DATETIME="$(date +%d.%m.%Y\ %H:%M:%S)"
LAST_IP=$(cat $DIR/ip)
STYLE="$(cat $DIR/style.txt)"
REFRESH=4
VANHAT_PERHE="$(cat $GITHUB_KUVAT/index.html || echo '')"  ## vaikka polku muuttuu, skripti ...
VANHAT_HAAT="$(cat $GITHUB_HAAT/index.html || echo '')"    ## ... silti toimii

function logInfo() {
    echo "[$DATETIME] [INFO]  : $1"
}

function logError() {
    echo "[$DATETIME] [ERROR] : $1" >> /dev/stderr
}

function fail() {
    logError "$1"
    exit 1
}

function failJaPalautaVanhatSivut() {
    echo "$VANHAT_PERHE" > $GITHUB_KUVAT/index.html
    echo "$VANHAT_HAAT" > $GITHUB_HAAT/haat/index.html
    fail "$1. Sivuja ei viety nettiin ja palautettu vanhat index.html:t."
}

function onkoIpValidi() {
    local ip; ip="$1"
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];
        then return 0
        else return 1
    fi
}

mkdir -p $GITHUB_KUVAT
mkdir -p $GITHUB_HAAT

                            currentIp=$(curl -s -m 20 ifconfig.me 2> /dev/null)
onkoIpValidi $currentIp ||  currentIp=$(curl -s -m 20 api.ipify.org 2> /dev/null)
onkoIpValidi $currentIp ||  currentIp=$(curl -s -m 20 ipinfo.io/ip 2> /dev/null)
onkoIpValidi $currentIp ||  fail "keskeytetään, koska kolmen eri ip-palvelun jälkeen ei saatu validia ip-osoitetta, vaan: '$currentIp'"

skripti="$(cat /home/ubuntu/häät/skripti.js)"
urli="https://${currentIp}:42615"
sivutPerhe="\
  <!doctype html>
  <html lang='fi'>
    <head>
      <meta charset='utf-8'>
      <meta name='viewport' content='width=device-width, initial-scale=1'>
      <meta name='robots' content='noindex'>
      <title>Välimaan perhe-albumi</title>
      $STYLE
    </head>
    <body>
      <br><br><br><br><br>
      <h1>Siirrytään <a href='$urli' target='_self'><strong>perhe-albumiin</strong></a><button id='laskuri'>Javascript pois päältä. Siirry linkistä!</button></h1>
      <script>
        'use strict';
        const urli = '$urli';
        let secsLeft = $REFRESH;
        $skripti
      </script>
    </body>
  </html>"

urli="https://${currentIp}:57820"
sivutHaat="\
  <!doctype html>
  <html lang='fi'>
    <head>
      <meta charset='utf-8'>
      <meta name='viewport' content='width=device-width, initial-scale=1'>
      <meta name='robots' content='noindex'>
      <title>Vilman & Juuson hääkuvat</title>
      $STYLE
    </head>
    <body>
      <br><br><br><br><br>
      <h1>Siirrytään <a href='$urli' target='_self'><strong>👰*Hääkuviin*🤵...</strong></a><strong><button id='laskuri'>Javascript pois päältä. Siirry linkistä!</button></strong></h1>
      <script>
        'use strict';
        const urli = '$urli';
        let secsLeft = $REFRESH;
        $skripti
      </script>
    </body>
  </html>"

if ! [ "$currentIp" = "$LAST_IP" ]; then
    logInfo "ip osoite on vaihtunut vanhasta '$LAST_IP' uuteen '$currentIp', ajetaan päivitys gitillä githubiin!"
elif ! [ "$VANHAT_PERHE" = "$sivutPerhe" ] || ! [ "$VANHAT_HAAT" = "$sivutHaat" ]; then
    logInfo "nettisivut ovat päivittyneet, ajetaan päivitys gitillä githubiin!"
else
    exit 0
fi

## Sivujen päivitys tehtävä ennen gittejä, mutta epäonnistuessa palautettava, että yritettäisiin uudestaan
echo "$sivutPerhe" > $GITHUB_KUVAT/index.html
echo "$sivutHaat" > $GITHUB_HAAT/index.html

cd $GITHUB_SIVUT || failJaPalautaVanhatSivut "keskeytetään, koska ei voida päivittää: github-sivujen kansioon ei pääsyä"
git pull \
    && git add --all \
    && git commit -m "Sivut päivitetty automaagisesti ajalla $DATETIME" \
    && git push \
    || failJaPalautaVanhatSivut "git:llä sivujen päivittäminen epäonnistui, keskeytetään"

## Ip osoite päivitetään uuteen vain jos kaikki skriptissä onnistuu!
echo $currentIp > $DIR/ip
