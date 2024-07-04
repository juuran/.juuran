#!/bin/bash

## Skripti, jolla rpi eli photoprism valokuvaserveri päivittää internet sivunsa.
## Tälle ei tehdä aliasta tai muutakaan kikkailua, vain säilössä täällä repossa.

DIR="/home/ubuntu/photoprism/sivut"
SIVUT_DIR="/home/ubuntu/github-sivut/juuran.github.io"
DATETIME="[$(date +%d.%m.%Y\ %H:%M:%S)]"
LAST_IP=$(cat $DIR/ip)
STYLE="$(cat $DIR/style.txt)"
REFRESH=4

function logInfo() {
    echo "$DATETIME [INFO]  : $1"
}

function logError() {
    echo "$DATETIME [ERROR] : $1" >> /dev/stderr
}

function fail() {
    logError "$1"
    exit 1
}

function failJaPalautaVanhatSivut() {
    echo "$VANHAT_PERHE" > $SIVUT_DIR/perhe-albumi/index.html
    echo "$VANHAT_HAAT" > $SIVUT_DIR/haat/index.html
    fail "$1"
}


# logInfo "ajetaan skripti github-sivujen päivittämiseksi"  ## vähän 0-informaatiota
currentIp=$(curl -s -m 20 ifconfig.me 2> /dev/null) \
    || currentIp=$(curl -s -m 20 api.ipify.org 2> /dev/null) \
    || currentIp=$(curl -s -m 20 ipinfo.io/ip 2> /dev/null) \
    || fail "keskeytetään, koska ei pääsyä nettiin tai kaikki ip tarkistus palvelut ovat alhaalla"

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
      <h2>Siirrytään <a href='$urli' target='_self'><strong>👰*Hääkuviin*🤵...</strong></a><strong><button id='laskuri'>Javascript pois päältä. Siirry linkistä!</button></strong></h2>
      <script>
        'use strict';
        const urli = '$urli';
        let secsLeft = $REFRESH;
        $skripti
      </script>
    </body>
  </html>"

VANHAT_PERHE="$(cat $SIVUT_DIR/perhe-albumi/index.html)"
VANHAT_HAAT="$(cat $SIVUT_DIR/haat/index.html)"

if ! [ "$currentIp" = "$LAST_IP" ]; then
   logInfo "ip osoite on vaihtunut vanhasta '$LAST_IP' uuteen '$currentIp', päivitetään sivutPerhe!"
elif ! [ "$VANHAT_PERHE" = "$sivutPerhe" ] || ! [ "$VANHAT_HAAT" = "$sivutHaat" ]; then
   logInfo "nettisivut ovat päivittyneet, ajetaan päivitys gitillä githubiin!"
else
   exit 0
fi

if [[ $currentIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];
   then logInfo "saatu ip osoite '$currentIp' on validi"
   else fail "keskeytetään tallentamatta uutta ip osoitetta tai sivuja, koska saatu ip ei ole validi: '$currentIp'"
fi

## Sivujen päivitys tehtävä ennen gittejä, mutta epäonnistuessa palautettava, että yritettäisiin uudestaan
echo "$sivutPerhe" > $SIVUT_DIR/perhe-albumi/index.html
echo "$sivutHaat" > $SIVUT_DIR/haat/index.html

cd $SIVUT_DIR || failJaPalautaVanhatSivut "keskeytetään, koska ei voida päivittää: github-sivujen kansioon ei pääsyä"
git pull \
   && git commit -am "Sivut päivitetty automaagisesti ajalla $DATETIME" \
   && git push \
   || failJaPalautaVanhatSivut "git:llä sivujen päivittäminen epäonnistui, keskeytetään"

## Ip osoite päivitetään uuteen vain jos kaikki skriptissä onnistuu!
echo $currentIp > $DIR/ip
