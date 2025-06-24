_This repo exists to make life with Unix configs and scripts "fun", or at least more so._

**_Cen tästä cäy, <br> saa kaiken woivo(ttelu)n heittää_**


# Näin cäyttelet

Alustat sa caiken tällä (lukien mucaan alimoduulit):

```
git clone --recurse-submodules https://github.com/juuran/.juuran.git
```

tahi tilalle `git@github.com:juuran/.juuran.git`

Jos haluat sa kaiken stow'aa (paitsi tämän READMEen) – muistapa myös .juuran cansioon mennä!

```
stow */ --ignore=.ssh/config
```

Ja jospa yhden vain

```
stow yksi
```


## Yhden komennon asennus laiscoille
```
cd && \
git clone --recurse-submodules git@github.com:juuran/.juuran.git && \
cd .juuran && \
stow */ '--ignore=.ssh/*'
cd
```

Jos välttämättä haluat tuon ssh:n kutaleen (josta rehellisesti enemmän haittaa on
kuin hyötyä, ollut), niin sitten jätä pois --ignore.


# Päivittää voit myös ilman tuscaa

```
git pull --recurse-submodules
```

tahi tiirailla wain

```
git fetch --all --prune --recurse-submodules
```

## _Loput löydät sa manuaalista!_
