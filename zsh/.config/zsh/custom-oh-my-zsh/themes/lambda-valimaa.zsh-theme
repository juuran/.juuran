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
    prompt_symbol="${LV_SEGMENT_SPACE}❯ "
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
    if (( $LV_RETVAL == 0 )); then
        prompt_segment ${LV_COLOR_LAMBDA} "λ%{$reset_color%}"
    else
        prompt_segment ${LV_COLOR_ERROR_BOLD} "λ%{$reset_color%}"
    fi
    
    prompt_segment ${LV_COLOR_CONTEXT} "${LV_SEGMENT_SPACE}%n@%m"
}

# Dir: current working directory
function prompt_dir() {
    local dir=${(%):-%3~}
    if [[ "$dir" == "~"* ]]; then
        prompt_segment ${LV_COLOR_DIR_TEXT} "${LV_SEGMENT_SPACE}%3~/"
    elif [[ "$dir" == "/"* ]]; then
        prompt_segment ${LV_COLOR_DIR_TEXT} "${LV_SEGMENT_SPACE}%3~"
    else
        prompt_segment "%f" "${LV_SEGMENT_SPACE}${LV_COLOR_DOTDOTDOT}…${LV_COLOR_DIR_TEXT}/%3~/"
    fi
}

# Git: branch/detached head, dirty & stashed status
function precache_git() {
    local repo_path now
    now="$EPOCHSECONDS"
    
    ## cachen käyttö vai ei
    if [[ "$LV_LAST_PWD" == "$PWD" ]] && (( (LV_LAST_TIME_CHECKED + LV_CACHE_VALID_SECONDS) > now )); then
        return  ## käytetään cachea, jos pysytty samassa polussa vain kotvasen
    elif ! repo_path=$(command git rev-parse --git-dir 2>/dev/null); then
        LV_CACHED_GIT_PROMPT=""  ## jos taas ei git kansio, tyhjätään cache
        return
    fi

    local ref dirty status_color ahead behind branch_char stash_char temp_space mode
    
    ## zsh:n oma version control system -tieto haetaan, kun suoritus alkaa
    vcs_info

    ## likainen git status eri väriseksi
    dirty=$(parse_git_dirty)
    if [[ -n "$dirty" ]]; then
        status_color="${LV_COLOR_GIT_NEUTRAL}"
    else
        status_color="${LV_COLOR_GIT_GOOD}"
    fi

    ## edellä vai jäljessä
    ref=$(command git symbolic-ref HEAD 2> /dev/null)
    read behind ahead <<< "$(
        git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
    )"
    if (( ahead > 0 && behind > 0 )); then
        branch_char="${LV_COLOR_ERROR} ⇅"
    elif (( ahead > 0 )); then
        branch_char="${LV_COLOR_GIT_NEUTRAL} ↧"
    elif (( behind > 0 )); then
        branch_char="${LV_COLOR_GIT_NEUTRAL} ↥"
    fi

    ## onko stäshiä?
    if [ -e "$repo_path/logs/refs/stash" ]; then
        stash_char="${LV_COLOR_GIT_NEUTRAL} ⚹"
    fi

    ## onko erikoistila päällä gitissä?
    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
        [[ $COMPACT_MODE == 'true' ]] && temp_space="" || temp_space=" "
        mode="${temp_space}${LV_COLOR_GIT_NEUTRAL}<B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
        mode="${temp_space}${LV_COLOR_GIT_NEUTRAL}>M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
        mode="${temp_space}${LV_COLOR_ERROR}>R>"
    fi

    ## cachetus nopeuttaa kummasti
    LV_CACHED_GIT_PROMPT="${status_color}${LV_SEGMENT_SPACE}${${ref:gs/%/%%}/refs\/heads\//}${vcs_info_msg_0_%% }${branch_char}${stash_char}${mode}"
}

function prompt_cached_git() {
    print -nr -- "$LV_CACHED_GIT_PROMPT"
}


## Main prompt
function lv_build_prompt() {
    LV_RETVAL=$?
    precache_git

    ## tämä muuttuja säätää zsh:ssä promptin ulkonäköä (apufunktioidensa ohella)
    PROMPT="$(
        prompt_status_context
        prompt_dir
        prompt_cached_git
        prompt_end
    )"

    LV_LAST_PWD="$PWD"
    LV_LAST_TIME_CHECKED="$EPOCHSECONDS"
}


function main() {
    export LV_LAST_PWD LV_LAST_TIME_CHECKED LV_CACHED_GIT_PROMPT LV_SEGMENT_SPACE LV_CACHE_VALID_SECONDS

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
        then    LV_SEGMENT_SPACE=" "
        else    LV_SEGMENT_SPACE="  "
    fi

    ## esiasetukset (version control system info)
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr "${LV_COLOR_WARN}⋇"
    zstyle ':vcs_info:*' unstagedstr "${LV_COLOR_WARNER}*"
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'

    LV_CACHE_VALID_SECONDS=1
    LV_LAST_TIME_CHECKED=-1  ## aluksi ei mitään, oikea arvo asettuu kun zsh ajaa lv_build_prompt oman logiikkansa mukaan

    ## itse suoritus asetetaan zsh:ssä tähän komentoon
    add-zsh-hook precmd lv_build_prompt
}

main
