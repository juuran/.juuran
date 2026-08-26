## Huippuunsa hiottu lambda teeman mukaelma, jonka rakensin agnoster
## teeman pohjalta, koska siinä oli kunnollinen ja ymmärrettävän 
## ohjelmoinnillinen pohja. Tähän tuli ehkä (taas) käytettyä "hieman"
## liikaa aikaa, mutta kyllähän tätä kestää onneksi katsoakin!
##
## Näyttää kivoilla väreillä:
## - onnistuiko edellinen komento
## - polun tiettyyn rajaan asti perässään aina / -merkki
## - gitin tiedot kattavasti kys. hakemistolle
##

# Begin a segment
# Takes an argument: foreground.
function prompt_segment() {
    local fg msg
    fg="$1"
    msg="$2"

    print -nr -- "%{$fg%}${msg}"
}

# End the prompt, closing any open segments
function prompt_end() {
    local prompt_symbol color
    prompt_symbol="${SEGMENT_SPACE}❯ "
    ## eri väri jos olet superuser
    if (( EUID == 0))
        then    color="${LV_COLOR_PROMPT_GOD}"
        else    color="${LV_COLOR_PROMPT_NORMAL}"
    fi
    print -nr -- "%{%k%}%{%f%}${color}${prompt_symbol}%{$reset_color%}"
}


### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Status:
# - was there an error
function prompt_status_context() {
    if (( $RETVAL == 0 )); then
        prompt_segment ${LV_COLOR_LAMBDA} "λ%{$reset_color%}"
    else
        prompt_segment ${LV_COLOR_ERROR_BOLD} "λ%{$reset_color%}"
    fi
    
    prompt_segment ${LV_COLOR_CONTEXT} "${SEGMENT_SPACE}%n@%m"
}

# Dir: current working directory
function prompt_dir() {
    local dir=${(%):-%3~}
    if [[ "$dir" == "~"* ]]; then
        prompt_segment ${LV_COLOR_DIR_TEXT} "${SEGMENT_SPACE}%3~/"
    elif [[ "$dir" == "/"* ]]; then
        prompt_segment ${LV_COLOR_DIR_TEXT} "${SEGMENT_SPACE}%3~"
    else
        prompt_segment "%f" "${SEGMENT_SPACE}${LV_COLOR_DOTDOTDOT}…${LV_COLOR_DIR_TEXT}/%3~/"
    fi
}

# Git: branch/detached head, dirty & stashed status
function precache_git() {
    local ref dirty repo_path mode temp_space status_color
    
    if [[ "$LAST_PWD" == "$PWD" ]]; then  ## sama kansio kuin viimeksi, ei tarvitse cachettaa mitään uutta
        return
    fi

    if ! repo_path=$(command git rev-parse --git-dir 2>/dev/null); then  ## tyhjätään cache ja poistutaan, ellei git kansio
        CACHED_GIT_PROMPT=""
        return
    fi

    dirty=$(parse_git_dirty)
    if [[ -n $dirty ]]; then
        status_color="${LV_COLOR_GIT_NEUTRAL}"
    else
        status_color="${LV_COLOR_GIT_GOOD}"
    fi

    ref=$(command git symbolic-ref HEAD 2> /dev/null)
    local ahead behind PL_BRANCH_CHAR PL_STASH_CHAR
    read behind ahead <<< "$(
        git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
    )"
    if (( ahead > 0 && behind > 0 )); then
        PL_BRANCH_CHAR="${LV_COLOR_ERROR} ⇅"
    elif (( ahead > 0 )); then
        PL_BRANCH_CHAR="${LV_COLOR_GIT_NEUTRAL} ↥"
    elif (( behind > 0 )); then
        PL_BRANCH_CHAR="${LV_COLOR_GIT_NEUTRAL} ↧"
    fi

    if [ -e "$repo_path/logs/refs/stash" ]; then
        PL_STASH_CHAR="${LV_COLOR_GIT_NEUTRAL} ⚹"
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
        [[ $COMPACT_MODE == 'true' ]] && temp_space="" || temp_space=" "
        mode="${temp_space}${LV_COLOR_GIT_NEUTRAL}<B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
        mode="${temp_space}${LV_COLOR_GIT_NEUTRAL}>M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
        mode="${temp_space}${LV_COLOR_ERROR}>R>"
    fi

    ## cachetus nopeuttaa kummasti
    CACHED_GIT_PROMPT="${status_color}${SEGMENT_SPACE}${${ref:gs/%/%%}/refs\/heads\//}${vcs_info_msg_0_%% }${PL_BRANCH_CHAR}${PL_STASH_CHAR}${mode}"
}

function prompt_cached_git() {
    print -nr -- "$CACHED_GIT_PROMPT"
}


## Main prompt
function lv_build_prompt() {
    RETVAL=$?
    
    precache_git
    PROMPT="$(
        prompt_status_context
        prompt_dir
        prompt_cached_git
        prompt_end
    )"

    LAST_PWD="$PWD"
}


function main() {
    export LAST_PWD CACHED_GIT_PROMPT SEGMENT_SPACE

    LV_COLOR_ERROR_BOLD="%{$fg_bold[red]%}"     ## bold punainen
    LV_COLOR_ERROR='%{%F{1}%}'                  ## punainen, (124, 197, 160, 9, 1)
    LV_COLOR_GIT_GOOD='%{%F{41}%}'              ## vihreä (47, 120, 41)
    LV_COLOR_GIT_NEUTRAL='%{%F{43}%}'           ## sinisempi (43, 44, 81)
    LV_COLOR_DOTDOTDOT='%{%F{102}%}'            ## harmaa (244, 247, 102)
    LV_COLOR_DIR_TEXT='%{%F{152}%}'             ## "polun väri", esim joku harmahtava (152, 103, 145, 146)
    LV_COLOR_LAMBDA="%{$fg_bold[white]%}"       ## kirkkaan valkoinen (231, 256)
    LV_COLOR_WARN='%{%F{227}%}'                 ## keltainen (227, 142)
    LV_COLOR_WARNER='%{%F{208}%}'               ## oranssi (208, 130)
    LV_COLOR_PROMPT_NORMAL='%{%F{251}%}'        ## promptimerkin väri normaalisti, valkoinen
    LV_COLOR_PROMPT_GOD='%{%F{226}%}'           ## promptimerkin väri jos olet root, kultainen (226)
    LV_COLOR_CONTEXT='%{%F{139}%}'              ## "hostin nimi", joku hillitty (140, 146, 139)

    if [[ $LAMBDA_VALIMAA_COMPACT_MODE == 'true' ]]
        then    SEGMENT_SPACE=" "
        else    SEGMENT_SPACE="  "
    fi

    ## esiasetukset (version control system info)
    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr "${LV_COLOR_WARN}⋇"
    zstyle ':vcs_info:*' unstagedstr "${LV_COLOR_WARNER}*"
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info

    unsetopt prompt_subst

    ## itse suoritus asetetaan zsh:ssä tähän komentoon
    add-zsh-hook precmd lv_build_prompt
}

main
