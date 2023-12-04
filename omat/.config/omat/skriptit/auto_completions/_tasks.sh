#compdef tasks.sh

_tasks_ehdotukset() {
  local -a komennot muokattavat;

  komennot=(
    edit:'Muokkaa aiempaa merkintää'
    path:'Näytä koko polku tiedostolle'
    all:'Näytä kaikki merkinnät'
    ignored:'Näytä vain "ignoratut" merkinnät'
    undone:'Vain tekemättömät näytetään'
    --help:"Näytä helppi"
  )

  _arguments -C \
    '1:cmd:->starting_point' \
    '*:: :->args'

  case "$state" in
  starting_point)
    _describe -t komennot 'commands' komennot
    ;;
  *)
    case $words[1] in
    edit)

      ## Tällaisella karmealla loitsulla "paremmassa" zsh:ssä otetaan taulukko joka katkaistu \n kohdalta:
      IFS=$'\n' raakaData=($(/home/c945fvc/.config/omat/skriptit/tasks.sh autocomplete_edit))
      size="${#raakaData}"

      ## Oikeasti, kuka sanoi että zsh olisi yhtään parempi kuin bash... Tämä on jotain ihan hirveää.
      typeset -Z 0 j  ## Tällä ilmeisesti voi luoda jotain että pädättävisä niin ja niin monella nollalla. Nyt 0.
      for ((indeksi=1; indeksi<$size; indeksi++)); do
        j=$indeksi
        # muokattavat+=( "Tunniste_$j:${raakaData[$j]}" )
        muokattavat+=( "Tunniste_${j}:${raakaData[$indeksi]}" )
      done

      _describe -t output 'Aiemman merkinnän editoimiseen' muokattavat

      ;;
    esac
    ;;
  esac
}

_tasks_ehdotukset
