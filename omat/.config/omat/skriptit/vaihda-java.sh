#!/bin/bash

## Tätä tarvitaan taas, koska RHEL ei osaa "alternatives" komentoa käyttää.

## HUOM! failia käytettävä oudosti luultavasti koska sourcataan .zshrc:ssä, muuten exittaa koko shellin!
function fail() {
    >&2 echo -e "vaihda-java.sh: $*"
    exit 1
}


command -v unlink &> /dev/null || return $(fail "Ei löytynyt riippuvuutta unlink.")
command -v ln &> /dev/null || return $(fail "Ei löytynyt riippuvuutta ln.")

noOfArgs=$#
[ $noOfArgs -gt 0 ] && echo "Argumentti havaittu, mutta sitäpä ei käytetä."


function vaihda_java() {
    

    local defaultJava java17 java25 javaToSet versioNimi
    
    defaultJava=/usr/lib/jvm/default
    java17=/usr/lib/jvm/java-17-openjdk-17.0.20.0.8-1.2.el9.x86_64
    java25=/usr/lib/jvm/java-25-openjdk

    echo "Vaihdetaan oletus java versio. Mikä laitetaan oletukseksi?"
    select java in "Java-17" "Java-25" "Nykyinen?" "Peruuta"; do
        case $java in
            Java-17)
                javaToSet="$java17"
                versioNimi="java-17"
                break;
            ;;
            Java-25)
                javaToSet="$java25"
                versioNimi="java-25"
                break;
            ;;
            Nykyinen?)
                echo -e "\nNykyinen Java versio on:\n"
                ls --color=always -alh $defaultJava || return $(fail "Ei löydetty vaadittua symbolinkkiä.")
                return 0
            ;;
            Peruuta)
                echo "Peruutetaan..."
                return 0
        esac
    done

    currentJava="$(readlink -f $defaultJava)"
    if [ "$currentJava" = "$javaToSet" ]; then
        return $(fail "Nykyinen Java on jo se versio, johon yrität vaihtaa. Eipä tehdä mitään.")
    fi

    sudo unlink $defaultJava
    sudo ln --symbolic $javaToSet $defaultJava || return $(fail "Ei voitu luoda uutta symbolinkkiä. Vaihto epäonnistui.")

    ## vaihdetaan myös /bin/java osoitteisiin javat!
    for osoite in /bin/java /bin/javac /bin/javadoc /bin/javap; do
        ## Poistetaan ensin vanhat...
        sudo unlink $osoite

        tmpLinkki=$(readlink -f $defaultJava)
        ## tämä viittaa siis osoitteeseen tyyliin /usr/lib/jvm/java-XX-openjdk
        uusiLinkki=${tmpLinkki}${osoite}

        ## ... ja asetetaan sitten uudet. (Muista, TARGET LINK_NAME.)
        sudo ln --symbolic $uusiLinkki $osoite || return $(fail "Ei voitu luoda uutta linkkiä osoitteeseen: $osoite")
    done

    ## vielä exporttaus...
    JAVA_HOME=$(readlink -f /bin/java) || return $(fail "JAVA_HOMEa ei voitu asettaa")
    export JAVA_HOME

    echo -e "Onnistuneesti vaihdettu java-versioksi $versioNimi!\n"
    ls --color=always -alh $defaultJava | grep $versioNimi
    ls --color=always -alh /bin/java* | grep $versioNimi
    echo "JAVA_HOME=$JAVA_HOME" | grep $versioNimi
}

