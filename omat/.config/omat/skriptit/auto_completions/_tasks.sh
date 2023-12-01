#compdef tasks.sh

local -a subCommands
subCommands=(
  "path:Näytä koko polku tiedostolle"
  "all:Näytä kaikki merkinnät"
  "ignored:Näytä vain \"ignoratut\" merkinnät"
  "undone:Vain tekemättömät näytetään"
  "add:Lisää uusi tehtävä -> \"todo.txt\""
  "--help:Tulostaa helpin"
)
_describe commands subCommands
