## -------------- omat muuttujat -------------- ##
ZSH_AUTOSUGGEST_HISTORY_IGNORE="cd *"
export SKRIPTIT_POLKU=~/.juuran/omat/.config/omat/skriptit

fpath+=( $SKRIPTIT_POLKU/auto_completions ) ## tarvitaan komentojen syöttämiseksi

if [ "$USER" = c945fvc ] || [ "$USER" = juuran ] || [ "$USER" = juuso ]; then
    # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
    # Initialization code that may require console input (password prompts, [y/n]
    # confirmations, etc.) must go above this block; everything else may go below.
    if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
        source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
    fi
fi

## tulostetaan neofetchillä kauniihko inhvo-ruutu kerran päivässä (jos neofetch löytyy)
if command -v neofetch > /dev/null && [ "$(date +%j)" != "$(cat ~/.neofetched 2>/dev/null)" ]; then
    date +%j > ~/.neofetched  # day of year
    neofetch
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.config/zsh/oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
if [ "$USER" = c945fvc ]; then   ## kela
    ZSH_THEME="powerlevel10k/powerlevel10k"

elif [ "$USER" = juuran ]; then  ## windows oma kone
    ZSH_THEME="lambda-valimaa"  ## lambda-valimaa, agnoster-valimaa, macovsky-valimaa
    ## hyviä originaaleja:  lukerandall, lambda, muse, zhann, sunaku, norm, macovsky miloshadzic, avit
    ##                      fletcherm, half-life (melkein: mira, fletcherm, robbyrussell, agnoster)

elif [ "$USER" = ubuntu ]; then  ## rpi
    ZSH_THEME="lambda-valimaa"

elif [ "$USER" = juuso ]; then   ## debian oma kone
    ZSH_THEME="powerlevel10k/powerlevel10k"

else                             ## muut koneet (mm. vilma)
    ZSH_THEME="random"
fi

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
ZSH_THEME_RANDOM_CANDIDATES=( "lambda-valimaa" "agnoster-valimaa" "macovsky-valimaa" ) #"zhann" "sunaku" "norm" "miloshadzic" "avit" "fletcherm" "agnoster" "half-life" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 210

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# (Tämä taitaa olla vähän aikaansa jäljessä. Ei ainakaan tajua cd ... aliasta)
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=~/.config/zsh/custom-oh-my-zsh

## eri koneiden pluginit
    # ( Which plugins would you like to load?
    #   Standard plugins can be found in $ZSH/plugins/
    #   Custom plugins may be added to $ZSH_CUSTOM/plugins/
    #   Example format: plugins=(rails git textmate ruby lighthouse)
    #   Add wisely, as too many plugins slow down shell startup. )
if [ "$HOST" = dev047tools1.kela.fi ]; then  ## kehityspalvelin
    plugins=(git-aliaksitta sudo web-search-riisuttu mvn npm jsontools zsh-syntax-highlighting zsh-autosuggestions yum docker)

elif [ "$USER" = c945fvc ]; then             ## kolaamo (deprekoitu!)
    plugins=(git-aliaksitta sudo web-search-riisuttu mvn npm jsontools zsh-syntax-highlighting zsh-autosuggestions oc)

elif [ "$USER" = juuran ]; then              ## oma windows
    plugins=(git-aliaksitta sudo zsh-autosuggestions zsh-syntax-highlighting mvn npm web-search)

elif [ "$USER" = ubuntu ]; then              ## rpi
    plugins=(git-aliaksitta sudo zsh-autosuggestions zsh-syntax-highlighting)

elif [ "$USER" = juuso ]; then               ## oma debian
    plugins=(git-aliaksitta sudo web-search-riisuttu mvn npm jsontools zsh-syntax-highlighting zsh-autosuggestions)

  ## default
else                                         ## muut (esim. vilman kone)
    plugins=(git-aliaksitta sudo zsh-autosuggestions zsh-syntax-highlighting)
fi

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"



## ------------- omat määrittelyt ------------- ##
## Eri värit tohon virheenkorjaajaan pitäis saada näin
grayish='fg=240'
greenish='fg=191'
reddish='fg=211'
# Declare the variable
typeset -A ZSH_HIGHLIGHT_STYLES
# ehreet
ZSH_HIGHLIGHT_STYLES[suffix-alias]=$greenish,underline     # =fg=blue,underline
ZSH_HIGHLIGHT_STYLES[precommand]=$greenish,underline       # =fg=blue,underline
ZSH_HIGHLIGHT_STYLES[autodirectory]=$greenish,underline    # =fg=blue,underline
ZSH_HIGHLIGHT_STYLES[arg0]=$greenish                       # =fg=blue
# punane
ZSH_HIGHLIGHT_STYLES[unknown-token]=$reddish,bold         # =fg=red,bold

## auto-suggestionsin väri
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=$grayish

# Pistetääns yhtenäinen historia molempaisiin shelleihin
unsetopt EXTENDED_HISTORY
HISTFILE=~/.shell_history
setopt histsavenodups

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='nano'
elif [ "$USER" = vilmasilvennoinen ]; then
    export EDITOR='nano'
else
    export EDITOR='nano -lci'
fi

ORIGINAL_PATH=$PATH
export ORIGINAL_PATH
function paivitaJavaHome() {
    local java_home; java_home=$(readlink -f /usr/bin/java)
    java_home=${java_home:0:-9}
    JAVA_HOME=$java_home
    PATH=$ORIGINAL_PATH:$JAVA_HOME/bin
}

## eri koneiden muuttujat (muut kuin plugarit)
if [ "$HOST" = dev047tools1.kela.fi ]; then
    ## asetettava JAVA_HOME, mutta update-alternatives linkkaa virheellisesti java ohjelmaan, ei kansioon
    paivitaJavaHome

    ## Ei tee tätä oletuksena git bashin kanssa
    export TERM=xterm-256color

    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    ## Lisäsin tämän nyt manuaalisesti .bashrc:stä
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    ## Omien skriptien globaalit muuttujat
    export NOTES_PATH="/home/c945fvc/notes"
    export EDITOR_IS_SUBL=false

    ## bash autocomplete search-logsia varten
    autoload -U +X bashcompinit
    bashcompinit
    slcPolku="$HOME/koodi/omat/lokilucia/.ei-hyppykoneelle/.search-logs-completions.sh"
    if [ -e "$slcPolku" ]; then
        source "$slcPolku"
    fi

    ## että edes git pull toimisi nginx kautta
    export GIT_SSL_NO_VERIFY=true

    ## tämä suotta ulisee, nyt käynnistyy aavistuksen hitaammin mutta se on ok!
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

elif [ "$USER" = c945fvc ]; then
    ## jos ohjelma olemassa, niin svidduun se non-breaking space
    if command -v setxkbmap > /dev/null &> /dev/null; then
        setxkbmap -option "nbsp:none"
    fi

    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    ## Lisäsin tämän nyt manuaalisesti .bashrc:stä
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    ## Add JBang to environment (ei kovin tärkeä)
    alias j!=jbang
    export PATH="$HOME/.jbang/bin:$PATH"

    ## Omien skriptien globaalit muuttujat
    export NOTES_PATH="/home/c945fvc/notes"
    export EDITOR_IS_SUBL=true

    ## bash autocomplete search-logsia varten
    autoload -U +X bashcompinit
    bashcompinit
    slcPolku="$HOME/yms/versionhallinnassa/bitbucket/lokilucia/.ei-hyppykoneelle/.search-logs-completions.sh"
    if [ -e "$slcPolku" ]; then
        source "$slcPolku"
    fi

    ## Laita tästä päälle, jos powerlevel alkaa ulisemaan
    ## neofetch alkoi
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

elif [ "$USER" = juuran ]; then
    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=241'
    export NOTES_PATH="/home/juuran/notes"

    ## nämä tarvitaan, koska bash-tyylisiä autocompleteja
    autoload -U +X bashcompinit
    bashcompinit

    ## nvm jutskat
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

    ## Näillä taikasanoilla saadaan winkkari ymmärtämään, missä pwd:ssä (winkkarissa CWD) kulloinkin
    ## ollaan. Nyt just ei jaksa kiinnostaa, mutta näin se toimii: The precmd_functions hook tells
    ## zsh what commands to run before displaying the prompt. "The printf statement is what we're using
    ## to append the sequence for setting the working directory with the Terminal. The
    ## $(wslpath -w "$PWD") bit will invoke the wslpath executable to convert the current directory into
    ## its Windows-like path. Using precmd_functions+= make sure we append the keep_current_path function
    ## to any existing function already defined for this hook."
    keep_current_path() {
        printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"
    }
    precmd_functions+=(keep_current_path)

elif [ "$USER" = ubuntu ]; then
    typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=241'

    ## nämä tarvitaan, koska bash-tyylisiä autocompleteja
    autoload -U +X bashcompinit
    bashcompinit

elif [ "$USER" = juuso ]; then
    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    export NOTES_PATH="/home/juuran/notes"

    ## nämä tarvitaan, koska bash-tyylisiä autocompleteja
    autoload -U +X bashcompinit
    bashcompinit

elif [ "$USER" = vilmasilvennoinen ]; then
    typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=246'
fi

## Nämä aliakset ylikirjoittaa kaiken, koska fuck the rest
if [ -f "$HOME/.shell_aliases" ]; then
    . $HOME/.shell_aliases
fi
