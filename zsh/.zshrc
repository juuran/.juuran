# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.config/zsh/oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="muse"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" "simple" "murilasso" "muse" "wuffers" "half-life")

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
zstyle ':omz:update' frequency 7

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
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

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git sudo web-search mvn zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nano'
else
  export EDITOR='nano'
fi

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


## -------------------- omat -------------------- ##

# Yeah, fuck those
if [ -f ~/.config/omat/skriptit/.aliases ]; then
    . ~/.config/omat/skriptit/.aliases
fi

## Svidduun se non-breaking space
if [ $USER = c945fvc ]; then
  setxkbmap -option "nbsp:none"
fi

# Pistetääns yhtenäinen historia molempaisiin shelleihin
unsetopt EXTENDED_HISTORY
HISTFILE=~/.shell_history

## Eri värit tohon virheenkorjaajaan pitäis saada näin
  # Declare the variable
  typeset -A ZSH_HIGHLIGHT_STYLES
  # ehreet
  ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=191,underline     # =fg=blue,underline
  ZSH_HIGHLIGHT_STYLES[precommand]=fg=191,underline       # =fg=blue,underline
  ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=191,underline    # =fg=blue,underline
  ZSH_HIGHLIGHT_STYLES[arg0]=fg=191                       # =fg=blue
  # punane
  ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=211,bold         # =fg=red,bold

## auto-suggestionsin väri
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

## Enpäs nyt jaksa keksiä parempaa paikkaan näille muistiinpanoille, joten
## muistiin panen ne tänne.
##   - ei ole haittaa siitä, että zsh skriptissäkin kirjoittaa "$muuttuja",
##     se ei vain ole pakollista, koska ei splittaa
##   - jos halutaan splittailla, niin aseta skriptin alussa:
##         setopt shwordsplit
##   - tällainen on mahdollista:
##         citytext="New York
##         Rio
##         Tokyo"
##
##         cityarray=( ${(f)citytext} )
##         - nyt cityarray on splitattu enttereiden kohdalta!
##   - jostain neronleimauksesta taulukot on 1-indeksisiä zsh:ssä... Niinpä
##     taulukoita käytellään tämän kanssa näin:
##         setopt KSH_ARRAYS
##         echo ${taul[0]}
##         ## tulostaa jotain
##         echo ${taul[1]}
##         ## tulostaa jotainMuuta
##
