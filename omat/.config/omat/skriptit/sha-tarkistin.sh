#!/bin/bash

source "$SKRIPTIT_POLKU/fail.sh"

printHelp() {
  echo ""
  echo "sha-tarkistin.sh"
  echo ""
  echo "Shan tarkistus \"helposti\", no ainakin helpommin"
  echo 
  echo "Käyttö:"
  echo "  sha-tarkistin.sh [OPTION]... tiedosto         tarkista *tiedosto*, jonka avain päätellään"
  echo "  sha-tarkistin.sh [OPTION]... tiedosto sha     tarkista *tiedosto* itse annettua *sha* argumenttia vasten"
  echo
  echo "Optiot:"
  echo "  -h, --help  näyttää tämän helpin"
  echo "  -s          tämän perään annettuna sha-ohjelma, jota käytetään tarkistukseen"
  exit 0
}

for arg in "$@"; do
  [ "$arg" == "--help" ] || [ "$arg" == "-h" ] && printHelp
done

## Optioiden käsittely
while getopts "s:" OPTION; do
  case "$OPTION" in
    s)
      shaSum="$OPTARG"
      ;;
    *)
      ## Perään lisättävien argumenttien lisäksi Bash käyttää samaa OPTARG -muuttujaa myös virheellisille vivuille!
      fail "Incorrect option "$OPTARG". Type -h for help!" 2
      ;;
  esac
done
## getopts käytön jälkeen täytyy "nollata" argumenttien indeksi, että saadaan "tavalliset" argumentit mukaan
shift "$(($OPTIND -1))"

## Ohjelmalogiikka
fileToCheck="$1"
shaToCheck="$2"  ## optional
shaSum="sha256sum"

if ! $shaSum --version &> /dev/null; then
    fail "The required $shaSum not found!" 2
fi

echo "This could take a while if the file is large..."

if [ -z "$shaToCheck" ]
    then $shaSum -c "$fileToCheck"
    else echo "$shaToCheck $fileToCheck" | $shaSum -c
fi
