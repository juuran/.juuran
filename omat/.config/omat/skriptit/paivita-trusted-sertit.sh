#!/bin/bash

## Apufunktiot, erinäiset alkutarkistukset
VERSION=1.0
KONEET="$*"

function fail() {
    >&2 echo -e "$(basename "$0"): $1"
    exitCode=1
    [ -n "$2" ] && exitCode=$2
    exit $exitCode
}

printHelp() {
    echo "        paivita-trusted-sertit.sh (v. $VERSION)"
    echo "skripti päivittää trusted sertin annetu(i)lle kone(e/i)lle"
    echo
    echo "käyttö:"
    echo "  ./$(basename "$0") KONEEN_NIMI..."
    echo
    echo "toiminta:"
    echo "- skripti tarvitsee vähintään yhden argumentin: koneen nimen (muodossa, jota ssh syö)"
    echo "    - jos käytetään useampaa konetta, erotetaan ne välilyönnillä"
    echo "- päivittää (kullekin) koneelle (yhden ja saman) sertin, jonka löydyttävä alikansiosta"
    echo "  tismalleen nimellä: ./varmenne/trustedcerts.jks"
    exit 0
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

[ -z "$KONEET" ] && fail "argumentiksi vaaditaan kone muodossa, jonka ssh ymmärtää – tarkemmin ks. --help"

echo -n "tarkistetaan kohdekone(id)en olemassaolo... "
for kone in $KONEET; do
    if ! ssh -q $kone true  ## kokeillaan ajaa koneella ohjelma true
        then fail "konetta '$kone' ei löydy tai siihen ei saada yhteyttä, keskeytetään"
    fi
done
echo "ok!"

echo
echo "uusi varmenne kopioidaan alikansiosta vain nimellä './varmenne/trustedcerts.jks', onhan kaikki oikein?"
echo "tulostetaan kansio komennolla: ls -alFh --color=always ./varmenne"
ls -alFh --color=always ./varmenne
echo "    (paina \"enter\" jos ok, \"ctrl + c\" jos haluat keskeyttää)"
read

## Varsinainen ohjelmalogiikka alkaa
for kone in $KONEET; do
    echo
    echo "=== aloitetaan sertin päivitys koneelle '$kone' ==="
    scp ./varmenne/trustedcerts.jks $kone:~/trustedcerts.jks_new || fail "tiedoston 'trustedcerts.jks' siirto koneelle '$kone' epäonnistui, keskeytetään"
    echo "siirrettiin sertti väliaikaisella nimellä 'trustedcerts.jks_new' koneelle '$kone'"
    ssh -t $kone '\
        passu=$(grep "server.ssl.trust-store-password" /opt/spring/services/opap-gateway/application.properties | cut -d = -f 2) ;\
        echo "nykyinen salasana on \"$passu\", vastaahan se uuden tiedoston salasanaa?"                                          ;\
        echo "    (paina \"enter\" jos ok, \"ctrl + c\" jos haluat keskeyttää)"                                                  ;\
        read                                                                                                                     ;\
        sudo su -c "cd /etc/pki/tls/certs/ && mv trustedcerts.jks trustedcerts.jks_old" || exit 1                                ;\
        echo "edellinen sertti tunnetaan nykyisin nimellä: trustedcerts.jks_old"                                                 ;\
        cd $HOME                                                                                                                 ;\
        mv trustedcerts.jks_new /tmp/                                                                                            ;\
        sudo su -c "cd /etc/pki/tls/certs/                                                                                       ;\
            mv /tmp/trustedcerts.jks_new ./trustedcerts.jks --verbose                                                            ;\
            chown root:root trustedcerts.jks                                                                                     ;\
            chmod 644 trustedcerts.jks" || exit 1                                                                                ;\
        echo                                                                                                                     ;\
        echo "tarkista vielä, että käyttöoikeus ja omistaja ovat samat kuin edellisessä"                                         ;\
        ls -lFh --color=always /etc/pki/tls/certs/trustedcerts.jks*                                                              ;\
        echo "ovatko tiedot samat?"                                                                                              ;\
        echo "    (paina \"enter\" jos ok, \"ctrl + c\" jos haluat keskeyttää)"                                                  ;\
        read                                                                                                                     ;\
        echo                                                                                                                     ;\
        echo "käynnistetään uudelleen opap..."                                                                                   ;\
        sudo su -c "systemctl restart spring-service-opap-gateway.service                                                        ;\
            sleep 1                                                                                                              ;\
            echo \"printataan 10 sek päästä opapin status...\"                                                                   ;\
            sleep 10                                                                                                             ;\
            systemctl status spring-service-opap-gateway.service | less -EX" || exit 0                                           ;\
        echo                                                                                                                     ;\
        ' || fail "sertin päivittäminen epäonnistui"
        echo "=== sertti päivitetty onnistuneesti koneelle '$kone' ==="
done

sleep 2
echo
echo "uudelleennimetään siirretty sertti, ettei sitä siirrettäisi uudestaan vahingossa"
mv ./varmenne/trustedcerts.jks ./varmenne/trustedcerts.jks_siirretty --verbose
echo "sertti päivitetty onnistuneesti koneilla $KONEET – muista seurata lokeilta että kaikki sujui ok"
