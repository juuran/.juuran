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
RIVIA_TULOSTETAAN=15 ## siis montako riviä temps-lokia nettisivuille tulostetaan
INFOBOX_TIEM=6  ## kamalasta nimestään huolimatta se, monesko kerta tulostaa infoboksin, esim. joka 10. kerta
REAL_SLEPTIEM=600  ## tavoite-aika unosille sekunteina
SLEPTIEM=$((REAL_SLEPTIEM - 4)) ## todellisesta ajasta pitää poistaa topin viemä kakkupala (n. 4 sex)
TEMPSLOG=/home/ubuntu/pp/juuson/sivut/temps.log
LOKI=/home/ubuntu/pp/juuson/sivut/loki.log
DATETIME="$(date +%d.%m.%Y\ %H:%M:%S)"

## funktiot tästä alas
function logInfo() {
    local pulinat="[$DATETIME] [INFO]  [--statuksen päivitys--] :"
    echo -e "$pulinat $1"
    echo -e "$pulinat $1" >> $LOKI
}

function logError() {
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

show_temps() {
    local gpuTemp=$(vcgencmd measure_temp)
    ## Näyttäisivat olevan tismalleen sama arvo aina, paitsi joskus mittaushetken virheen takia
    # cpuTempRaw=$(</sys/class/thermal/thermal_zone0/temp)
    # cpuTemp="temp=$((cpuTempRaw/1000)).$(((cpuTempRaw%1000)/100))'C"
    local clkRaw=$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    local clk="$((clkRaw/1000000)).$(((clkRaw%1000000)/100000))GHz"

    ## Napataan top:lta kahdesta "batch" arvosta vain jälkimmäinen, koska ensimmäisessä näkyy
    ## topin käynnistysaika, mikä vääristää cpu:n käyttöä yllättävän paljon (5-8 prosenttia)
    local topRaw="$(top -bn 2 | head -n 6)"
    local cpuUsage="$(echo "$topRaw" | grep --color=never -i %cpu | grep -oE -e '^.*id' )"
    local tasks="$(echo "$topRaw" | grep --color=never -i tasks)"
    UPTIME="$(echo "$topRaw" | grep --color=never -i 'top - ')"
    MEM="$(echo "$topRaw" | grep --color=never -i 'mib mem')"
    SWAP="$(echo "$topRaw" | grep --color=never -i 'mib swap')"
    DATETIME="$(date +%d.%m.%Y\ %H:%M:%S)"
    echo "$DATETIME  [$gpuTemp]   [clock=$clk]   [$cpuUsage]   [$tasks]"
}

valiaikaTieto() {
    echo "---------- Väliaikatietoja -----------"
    echo "    uptime:           [$UPTIME]"
    echo "    muistin käyttö:   [$MEM]"
    echo "    swapin käyttö :   [$SWAP]"
    echo "    RAID1:n kunto :   coming soon..."  ## TODO: tulossa on, mutta järki käteen (ja ostoksille!)
    echo "    prismien kunto:   ehkä, ehkä, ehkä tulee..."
    echo "--------------------------------------"
}

luoStatusSivut() {
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
        && git commit -m "Status päivitetty automaattisesti" \
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
        show_temps >> $TEMPSLOG
        if [[ $((i % INFOBOX_TIEM)) == 0 ]]; then
            valiaikaTieto >> $TEMPSLOG
            laitaMinutNettiin
        fi
        sleep $SLEPTIEM
        i=$((i+1))
    done
}

main
