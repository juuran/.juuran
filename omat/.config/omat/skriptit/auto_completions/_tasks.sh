#compdef tasks.sh

_add_note() {
  return 1
}

argumentit='( path\:"Näytä koko polku tiedostolle" all\:"Näytä kaikki merkinnät" ignored\:"Näytä vain \"ignoratut\" merkinnät" undone\:"Vain tekemättömät näytetään" )'

_arguments -s \
    '::argumentti:((add\:"hemmo"))' \  ## nyt loppu skillit kesken... pitää lukea lisää!
    "::argumentti:($argumentit)" \
    '--help[Näyttää helpin]' \
