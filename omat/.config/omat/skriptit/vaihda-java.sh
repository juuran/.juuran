#!/bin/bash

## Deprekoitu! Poista joskus. En vaihda javaa näillä näkyvin näin, mutta
## voihan tämä olla täällä esimerkkinä... jostain.

noOfArgs=$#
[ $noOfArgs -gt 0 ] && echo "Argumentti havaittu, mutta sitä ei käytetä."

defaultJavaSymbolink="/opt/kela/java/default"
java11="/opt/kela/java/openJDK/jdk-11.0.15+10"
java17="/opt/kela/java/openJDK/jdk-17.0.3+7"
java8="/opt/kela/java/ibm/java-x86_64-80/"
javaToSet=""

echo "Vaihdetaan oletus java versio. Mikä laitetaan oletukseksi?"
select java in "Java-8" "Java-11" "Java-17" "Nykyinen?" "Peruuta"; do
    case $java in
        Java-8)
            javaToSet="$java8"
            break;
        ;;
        Java-11)
            javaToSet="$java11"
            break;
        ;;
        Java-17)
            javaToSet="$java17"
            break;
        ;;
        Nykyinen?)
            echo -e "\nNykyinen Java versio on:\n"
            ls --color=always -alh $defaultJavaSymbolink
            exit 0;
        ;;
        Peruuta)
            echo "Peruutetaan..."
            exit 0
    esac
done

currentJava="$(readlink -f $defaultJavaSymbolink)"
if [ "$currentJava" == "$javaToSet" ]; then
    echo "Current Java is already the one you're trying to set. Nothing done."
    exit 0
fi

sudo rm $defaultJavaSymbolink || fail "Failed to remove!"
sudo ln --symbolic $javaToSet $defaultJavaSymbolink
echo -e "\nOletukseksi vaihdettu onnistuneesti '$javaToSet'!\n"
ls --color=always -alh $defaultJavaSymbolink
