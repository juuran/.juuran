#!/bin/bash

## "staattisesti linkatut" funktioni fail ja error (saa lainata!)
function error() {
    [ -z "$*" ] && return
    if [[ "$*" == "\n"* ]]; then
        kaikki="$*"
        >&2 echo -e "\n$(basename "$0"): ${kaikki:2}"
    else
        >&2 echo -e "$(basename "$0"): $*"
    fi
}

function fail() {
    error "$1"
    exitCode=1
    [ -n "$2" ] && exitCode=$2
    exit $exitCode
}


## GLOBAALIT MUUTTUJAT (älä arvostele siellä, tekevät skriptaamisesta siedettävää)
LINE=""
SECRET_NIMI=""
SEALED_FILE=""
IS_BACKED_UP=true
V="v. 1.0"
SKRIPTIN_NIMI="$(basename "$0")"

## APUFUNKTIOT

## lukee shellistä rivin ja laittaa sen arvoksi globaalille LINE muuttujalle
function readLine() {
    local prompti
    prompti="$1"
    read -rp "    >> $prompti" LINE
}

## poistaa luodut väliaikaiset resurssit ja poistuu virheviestillä tai ilman
function poistaJaPoistu() {
    local viesti
    viesti="$1"
    [[ -n "$SECRET_NIMI" ]] && oc get secret $SECRET_NIMI &> /dev/null && oc delete secret $SECRET_NIMI
    [[ -e "$SEALED_FILE" ]] && rm "$SEALED_FILE"

    echo "muutokset kumottu"
    [[ -n "$viesti" ]] && fail "$viesti" || exit 1
}

function handleSignals() {
    echo -e "\n\nsaatu lopetussignaali, kumotaan ja poistutaan"
    poistaJaPoistu
}

function luoVarakopio() {
    backupDir="./secrets_backup"
    if (mkdir -p $backupDir) then
        oc get secret $SECRET_NIMI -o yaml > $backupDir/$SECRET_NIMI.yaml || error "varakopioita ei voitu luoda, jatketaan silti"
        echo -e "varakopio luotu onnistuneesti \n(varakopiot voi kytkeä pois päältä -b vivulla, ks. --help)"
    else
        error "varakopiokansiota ei voitu luoda (oikeudet kunnossa?), jatketaan silti"
    fi
}

function oc_seal() {
    local secretYaml
    echo -e "\n--- aloitetaan sealed-secretin luonti ---"
    SEALED_FILE="sealed-$SECRET_NIMI.yaml";
    secretYaml=$(oc get secrets $SECRET_NIMI -o yaml) \
        || fail "Could not find secret, exiting with error..." 2

    ## luodaan sealed secret tiedosto tai epäonnistuessa kumotaan muutokset
    echo "$secretYaml" | kubeseal --controller-namespace sealed-secrets -o yaml --scope namespace-wide > $SEALED_FILE \
            || poistaJaPoistu "ei voitu luoda sealed-secretiä, keskeytetään..."

    echo "sealed-secret '$SEALED_FILE' luotu"

    [[ "$IS_BACKED_UP" == true ]] && luoVarakopio

    echo "poistetaan väliaikainen salaamaton secret namespacesta"
    oc delete secret $SECRET_NIMI || error "ei voitu poistaa secretiä $SECRET_NIMI openshiftistä, jatketaan yhtä kaikki"

    echo "--- sealed-secretin luonti onnistui ---"
}


## ESITARKISTUKSET

for arg in "$@"; do
    if [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
        echo ""
        echo "$SKRIPTIN_NIMI - luo sealed secretejä helposti ($V)"
        echo ""
        echo "Skripti luo syöttämiesi tietojen pohjalta sealed-secretin polkuun, jossa olet sekä niiden varakopiot ./secrets_backup"
        echo 'polkuun viemättä mitään versionhallintaan. Luo, mutta lopuksi poistaa väliaikaisen salaamattoman secretin. (Poistua voi'
        echo "turvallisesti koska vain SIGINTillä [Ctrl + C])"
        echo ""
        echo "Usage:"
        echo "    $SKRIPTIN_NIMI - aloittaa interaktiivisen secretin luonnin, vaatii toimiakseen ohjelmia: oc ja kubeseal"
        echo ""
        echo "Options:"
        echo "    -h, --help            printtaa tämän helpin"
        echo "    -b                    vipu, jolla otetaan varakopioiden luonti pois päältä"
        echo ""
        exit 0
    elif [[ "$arg" == "-b" ]]; then
        IS_BACKED_UP=false
    elif [ -n "$arg" ];then
        fail "skripti ei tue tätä parametriä, ks. --help"
    fi
done

command -v oc &> /dev/null              || fail "komento 'oc' vaaditaan tämän skriptin ajamiseksi"
command -v kubeseal &> /dev/null        || fail "komento 'kubeseal' vaaditaan tämän skriptin ajamiseksi"


## ITSE OHJELMA

function main() {
    local avainArvot=() literaalit
    trap 'handleSignals' SIGINT SIGTERM SIGQUIT

    echo "<<  $SKRIPTIN_NIMI ($V)  >>"

    ## tarkistetaan yhteys
    oc get secrets &> /dev/null \
        || fail 'oc ei saa yhteyttä, oletko varmasti kirjautunut oikeaan ympäristöön?\n(esim. "oc login -u $USER api.cp4apps.testikela.fi:6443  ## openshiftin IBM:n cp4apps testiklusteriin omalla puukkarilla")'

    echo -e "luo ja salaa secret yhdellä iskulla\n(syötä kentät avain-arvo pareina tyylillä avain=arvo)\n"

    ## secretin nimi
    readLine "anna secretille nimi: "
    SECRET_NIMI="$LINE"
    [[ -z "$SECRET_NIMI" ]] && fail "annetun secretin nimi ei voi olla tyhjä!"
    [[ "$SECRET_NIMI" == *" "* ]] && fail "annettava rivi ei saa sisältää välilyöntejä!"
    [[ -e "./sealed-$SECRET_NIMI.yaml" ]] && fail "samanniminen salattu tiedosto on jo olemassa eikä ohjelmointini salli ylikirjoittaa sitä..."

    ## varsinainen sisältö secretiin
    while true; do
        readLine "anna luotava avain-arvo pari (tai 'q' kun olet valmis): "
        if [[ -z "$LINE" ]]; then
            continue  ## enter ei tee mitään tässä
        elif [[ "$LINE" == "q" ]]; then
            break;
        elif [[ "$LINE" != *"="* ]]; then
            fail "ei sisältänyt merkkiä '=' \nKäsky on anettava \"java properties\" muotoisesti avain=arvo!"
        fi

        avainArvot+=("$LINE")
    done

    [[ -z "${avainArvot[*]}" ]] && fail "ei annettu yhtään avain-arvo paria, poistutaan tekemättä mitään"

    ## salaamattoman secretin luonti
    for avainArvo in "${avainArvot[@]}"; do
        literaalit="$literaalit--from-literal=$avainArvo "
    done

    luontiKomento="oc create secret generic $SECRET_NIMI ${literaalit}"
    echo -e "\nsuoritetaan komento annetuilla tiedoilla:"
    echo -e "    $luontiKomento\n"
    $luontiKomento || fail "\nsecretin luonti epäonnistui!\nkatso englanninkieliset virheen tiedot yltä"

    echo -e "\n(\n  HUOM! Avaimien arvot base64 muodossa\n  luotu väliaikainen secret tarkastettavaksi:\n)\n"
    oc get secret $SECRET_NIMI -o yaml || fail "\nsecretin haku epäonnistui, keskeytetään!"

    echo ""
    readLine "jos tämä on mielestäsi oikein paina [Enter], jos väärin 'q' tai koska vain [Ctrl + C]: "
    [[ "$LINE" == "q" ]] && echo "saatiin 'q', kumotaan muutokset" && poistaJaPoistu

    ## sealed-secretin luonti
    oc_seal
}

main
