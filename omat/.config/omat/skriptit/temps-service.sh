#!/bin/bash

## temps.sh service elikkä suomeksi palvelu, jos et tiennyt
## hoitaa seuraavat työt, kuten hienossa aamuöisessä doku-mentissani totesin:
##    systemd "palvelu" joka oikeasti toki skripti (toim. huom. tämä skripti)
##		    kutsuu show_tempsiä
##		    hoitaa lokituksen -> loki.log
##		    hoitaa kirjoituksen -> temps.log
##		    päivittää sivut joka 10. kerta tms
##		    nukkuu (toisin kuin minä)

## globaaleimmat muuttujat
RIVIA_TULOSTETAAN=22    ## siis montako riviä temps-lokia nettisivuille tulostetaan
INFOBOX_TIEM=6          ## kamalasta nimestään huolimatta se, monesko kerta tulostaa infoboksin, esim. joka 10. kerta
REAL_SLEPTIEM=50400     ## tavoite-aika unosille sekunteina (esim. 7200: 2h), nyt 14 h
SLEPTIEM=$((REAL_SLEPTIEM - 4)) ## todellisesta ajasta pitää poistaa topin viemä kakkupala (n. 4 sex)
TEMPSLOG=/home/ubuntu/pp/juuson/sivut/temps.log
LOKI=/home/ubuntu/pp/juuson/sivut/loki.log
DATETIME="$(date +%d.%m.%Y\ %H:%M:%S)"
show_temps="/home/ubuntu/.juuran/omat/.config/omat/skriptit/temps.sh"

upDate() {
    DATETIME="$(date +%d.%m.%Y\ %H:%M:%S)"
}

## funktiot tästä alas
function logInfo() {
    upDate
    local pulinat="[$DATETIME] [INFO]  [--statuksen päivitys--] :"
    echo -e "$pulinat $1"
    echo -e "$pulinat $1" >> $LOKI
}

function logError() {
    upDate
    local pulinat="[$DATETIME] [ERROR] [--statuksen päivitys--] :"
    >&2 echo -e "$pulinat $1"
    echo -e "$pulinat $1" >> $LOKI
}

## tätä en tosiaan keksinyt itse!
trapWithArg() {
    func="$1" ; shift
    for sig ; do
        trap "$func $sig" "$sig"
    done
}

handleSignals() {
    logInfo "signaali '$1' saatu - temps-service.sh lopetettu onnistuneesti"
    exit 0
}


luoStatusSivut() {
    upDate
    local status="$1"
    STATUS_SIVUT="\
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <meta name='robots' content='noindex'>
    <title>Kotiserverin kunto</title>
</head>
<body>
    <pre>
sivu luotu aikaleimalla [$DATETIME].

status report:
$status
    </pre>
</body>
"
}

laitaMinutNettiin() {
    logInfo "viedään status-sivut nettiin"
    if ! status="$(tail $TEMPSLOG -n $RIVIA_TULOSTETAAN)"; then
        logError "teilaaminen epäonnistui, onko tiedosto olemassa?"
        return 1
    fi

    luoStatusSivut "$status"

    local githubStatusPages="/home/ubuntu/github-sivut/juuran.github.io/status"  ## julkinen internet
    echo "$STATUS_SIVUT" > $githubStatusPages/index.html \
        || (logError "echottaminen epäonnistui, onhan tiedosto olemassa?" && return 1)

    ## en nyt tähän aikaan aamusta jaksa keksiä parempaakaan tapaa saada gitin tulosteita näkyviin kaikkialla
    gitinTulosteet=$(>&2 cd $githubStatusPages \
        && git pull \
        && git add index.html \
        && git commit -m "Status päivitetty temps-servicellä ajalla $DATETIME" \
        && git push)
    gitExitCode="$?"

    if [ "$gitExitCode" -ne 0 ]; then
        logError "statuksen päivitys epäonnistui koska git-hommailussa meni joku mönkään: \n$gitinTulosteet"
        return 1
    fi

    logInfo "status-sivut viety onnistuneesti gitiin"
}

## maini jossapa, ah, ikuinen luuppi!
main() {
    trapWithArg handleSignals SIGINT SIGQUIT SIGTERM SIGABRT

    logInfo "käynnistetty palvelu temps-service.sh."
    logInfo "(Kirjoitetaan temps.logiin joka $REAL_SLEPTIEM. sekunti ja päivitetään sivut infoboksin kanssa joka $INFOBOX_TIEM. kerta.)"

    i=1
    while true
    do
        if [[ $((i % INFOBOX_TIEM)) != 0 ]]; then
            $show_temps >> $TEMPSLOG
        else
            $show_temps more_info >> $TEMPSLOG
            laitaMinutNettiin
        fi

        sleep $SLEPTIEM
        i=$((i+1))
    done
}

main
