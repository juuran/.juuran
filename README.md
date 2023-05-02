_This repo exists to make life with Unix configs and scripts "fun", or at least more so._

**_Cen tästä cäy, <br> saa kaiken woivo(ttelu)n heittää_**

# Näin cäyttelet

Alustat sa caiken tällä (lukien mucaan alimoduulit):

    git clone --recurse-submodules https://github.com/juuran/.juuran.git

Jos haluat sa kaiken stow'aa (paitsi tämän READMEen)

    stow */

Ja jospa yhden vain

    stow yksi

# Päivittää voit myös ilman tuscaa

`git pull --recurse-submodules` tahi tiirailla `git fetch --all --prune --recurse-submodules`

## _Loput löydät sa manuaalista!_

### PS. Erikoistarpeet

Joscin se on sanottawa, että mikäli haluat sa saada kaicen näkymän ilman 'HEAD detached' <br>
ilmoitusta, teepä näin. (Tosin muista, hintana on alimoduulein näkyminen osana 'main' <br>
haaraa, mikä hieman valheellista lie... Mutta se on se hinta, koska muutoin aina yhden <br>
commitin kerrallansa checkouttaa ja siten irroittaa.)

    git clone git@github.com:juuran/.juuran.git && git -C .juuran submodule update --remote --merge
