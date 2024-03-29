#compdef tasks.sh

_tasks_ehdotukset() {
  local -a komennot muokattavat;

  komennot=(
    edit:'Muokkaa aiempaa merkintää'
    path:'Näytä koko polku tiedostolle'
    add:'Lisää uusi merkintä, toisena arugmenttina tiedosto (oletus todo.txt)'
    priority:'Näytä vain tärkeimmät tehtävät'
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
      ## Tällaisella loitsulla zsh:ssä otetaan taulukko joka katkaistu \n kohdalta:
      IFS=$'\n' raakaData=($($HOME/.config/omat/skriptit/tasks.sh autocomplete_edit))
      size="${#raakaData}"

      if [ "$size" -gt 99 ]
        then typeset -Z 3 j  ## Tällä luodaan kolmella 0:lla pädättävä numero
        else typeset -Z 2 j
      fi

      local indeksi
      for ((indeksi=1; indeksi<=$size; indeksi++)); do
        j=$indeksi
        # muokattavat+=( "Tunniste_$j:${raakaData[$j]}" )
        muokattavat+=( "$j: ${raakaData[$indeksi]}" )
      done

      _describe -t output 'Aiemman merkinnän editoimiseen' muokattavat
      ;;

    add)
      _arguments \
        ':muistpano:()' \
        "::polku:_files -W $NOTES_PATH"
      ;;

    esac
    ;;
  esac
}

_tasks_ehdotukset
