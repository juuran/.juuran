#!/bin/bash

noOfArgs=$#
[ $noOfArgs -gt 0 ] && echo "Argumentti havaittu, mutta sitä ei käytetä."

defaultJavaSymbolink="/opt/kela/java/default"
java11="/opt/kela/java/openJDK/jdk-11.0.15+10/"
java17="/opt/kela/java/openJDK/jdk-17.0.3+7/"
javaToSet=""

echo "Vaihdetaan oletus java versio. Mikä laitetaan oletukseksi?"
select java in "Java-11" "Java-17" "Nykyinen?" "Peruuta"; do
    case $java in
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
            echo
            exit 0;
        ;;
        Peruuta)
            echo "Peruutetaan..."
            exit 0
    esac
done

sudo rm $defaultJavaSymbolink
sudo ln --symbolic $javaToSet $defaultJavaSymbolink
echo -e "\nOletukseksi vaihdettu onnistuneesti '$javaToSet'!\n"
ls --color=always -alh $defaultJavaSymbolink
echo
