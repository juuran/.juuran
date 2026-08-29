
## Begin a segment
## Takes an argument: foreground.
function prompt_segment() {
    print -nr -- "$1"
}

### Prompt components
## Each component will draw itself, and hide itself if no information needs to be shown

## Status:
## - was there an error
function prompt_start() {
    local color_lambda color_user color_at color_host
    color_user="$LV_COLOR_USER"
    color_at="$LV_COLOR_AT_MACHINE"
    (( $LV_RETVAL == 0 ))       && color_lambda="$LV_COLOR_LAMBDA"      || color_lambda="$LV_COLOR_ERROR_BOLD"
    [[ -n $SSH_CONNECTION ]]    && color_host="$LV_COLOR_HOST_SSH"      || color_host="$LV_COLOR_HOST_NORMAL"

    if [[ $LV_TWO_ROW_MODE == true ]]; then  ## jos 2-rivinen, aloitetaan entterillä
        prompt_segment "
${color_lambda}λ%{$reset_color%}${LV_SEGMENT_SPACE}${color_user}%n${color_at}@${color_host}%m%{$reset_color%}"
    else
        prompt_segment "${color_lambda}λ%{$reset_color%}${LV_SEGMENT_SPACE}${color_user}%n${color_at}@${color_host}%m%{$reset_color%}${LV_SEGMENT_SPACE}"
    fi
}

## Dir: current working directory
function prompt_dir() {
    local dir=${(%):-%3~} locked symbo both dir_display
    
    [[ -w . ]] || locked='🔒'
    [[ $PWD != $(pwd -P) ]] && symbo='🔗'
    [[ -n "${locked}${symbo}" ]] && both="${locked}${symbo}${LV_SEGMENT_SPACE}"

    if [[ "$dir" == "~"* ]]; then
        dir_display="${LV_COLOR_DIR_TEXT}%3~/"
    elif [[ "$dir" == "/"* ]]; then
        dir_display="${LV_COLOR_DIR_TEXT}%3~"
    else
        dir_display="${LV_COLOR_DOTDOTDOT}…${LV_COLOR_DIR_TEXT}/%3~/"
    fi

    prompt_segment "${both}${dir_display}"
}

function get_tag() {
    local temp_tag
    if ! temp_tag="$(git describe --tags --exact-match HEAD 2> /dev/null)"; then
        return
    fi

    if [[ $LV_TWO_ROW_MODE == true ]]
        then  LV_TAG=" ${LV_COLOR_DOTDOTDOT}(tag: ${LV_COLOR_PROMPT_GOD}${temp_tag}${LV_COLOR_DOTDOTDOT})"
        else  LV_TAG=" ${LV_COLOR_DOTDOTDOT}(${LV_COLOR_PROMPT_GOD}${temp_tag}${LV_COLOR_DOTDOTDOT})"
    fi
}

## Git: branch/detached head, dirty & stashed status
function precache_git() {
    local repo_path now
    now="$EPOCHSECONDS"
    
    ## cachen y/n ja pikapoistumiset
    if [[ "$LV_LAST_PWD" == "$PWD" ]] && (( (LV_LAST_TIME_CHECKED + LV_CACHE_VALID_SECONDS) > now )); then
        return  ## käytetään cachea, jos pysytty samassa polussa vain kotvasen
    elif ! repo_path=$(command git rev-parse --git-dir 2>/dev/null); then
        LV_CACHED_GIT_PROMPT=""  ## jos taas ei git kansio, tyhjätään cache
        return
    fi

    local dirty status_color ref branch_or_detach ahead behind unsynced_char stash_char mode un_staged
    
    ## zsh:n oma version control system -tieto haetaan vasta, kun suoritus alkaa
    vcs_info

    ## likainen git status eri väriseksi
    dirty="${vcs_info_msg_0_}"
    if [[ "$dirty" == *"⋇"* ]] || [[ "$dirty" == *"*"* ]]; then  ## etsii "staged" ja "unstaged" merkkejä "String.contains"-tyylisesti
        status_color="${LV_COLOR_GIT_NEUTRAL}"
    else
        status_color="${LV_COLOR_GIT_GOOD}"
    fi

    LV_TAG=""
    if ref=$(command git symbolic-ref HEAD 2> /dev/null); then  ## haara löytyi
        branch_or_detach="${LV_SEGMENT_SPACE}${status_color}${${ref:gs/%/%%}/refs\/heads\//}"
        [[ $LV_TWO_ROW_MODE == true ]] && get_tag  ## kaksirivimoodissa haetaan tägi myös haarassa ollessa (koska tilaa näyttää se)

    else  ## ei haaraa, detached
        branch_or_detach="${LV_SEGMENT_SPACE}${LV_COLOR_ERROR}detached"
        get_tag  ## detachedin tapauksessa haetaan aina tägi, jos sellainen vain on!
    fi

    ## edellä vai jäljessä
    read behind ahead <<< "$(
        git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
    )"
    if (( ahead > 0 && behind > 0 )); then
        unsynced_char="${LV_COLOR_ERROR} ⇅"
    elif (( ahead > 0 )); then
        unsynced_char="${LV_COLOR_GIT_NEUTRAL} ↧"
    elif (( behind > 0 )); then
        unsynced_char="${LV_COLOR_GIT_NEUTRAL} ↥"
    fi

    ## onko stäshiä?
    if [ -e "$repo_path/logs/refs/stash" ]; then
        stash_char="${LV_COLOR_GIT_NEUTRAL} ⚹"
    fi

    ## onko erikoistila päällä gitissä?
    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
        mode="${LV_COLOR_GIT_NEUTRAL} <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
        mode="${LV_COLOR_GIT_NEUTRAL} >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
        mode="${LV_COLOR_ERROR} >R>"
    fi

    un_staged="${vcs_info_msg_0_%%}"; [[ -n "$un_staged" ]] && un_staged=" ${un_staged}"
    ## cachetus nopeuttaa kummasti
    LV_CACHED_GIT_PROMPT="${branch_or_detach}${un_staged}${LV_TAG}${unsynced_char}${stash_char}${mode}"
}

function prompt_cached_git() {
    prompt_segment "$LV_CACHED_GIT_PROMPT"
}

function prompt_exit_code() {  ## tätä kutsutaan aina ja vain kaksirivisessä moodissa, siksi enter molemmissa!
    local exitcode_printout
    if (($LV_RETVAL > 0 )); then
        prompt_segment "${LV_SEGMENT_SPACE}${LV_COLOR_DOTDOTDOT}(${LV_COLOR_WARNER}exitcode: $LV_RETVAL${LV_COLOR_DOTDOTDOT})
"
    else
        prompt_segment "
"
    fi
}

## End the prompt, closing any open segments
function prompt_end() {
    local prompt_symbol color_lambda
    prompt_symbol="${LV_SEGMENT_SPACE}❯ "
    if (( EUID == 0)); then                         ## super userin väri
            color_lambda="${LV_COLOR_PROMPT_GOD}"
        else                                        ## normikäyttäjän väri
            color_lambda="${LV_COLOR_PROMPT_NORMAL}"
    fi

    prompt_segment "${color_lambda}${prompt_symbol}%{$reset_color%}"
}

## Main prompt
function lv_build_prompt() {
    LV_RETVAL=$?

    ## dynaamiset (oletus)arvot tai .zshrc ENVeinä asetetut tehtävät nyt, koska "prompt" funktioissa eivät päivity!
    [[ -z "$LV_TWO_ROW_MODE" ]]         &&  LV_TWO_ROW_MODE=true
    [[ -z "$LV_COMPACT_MODE" ]]         &&  LV_COMPACT_MODE=true
    [[ -z "$LV_CACHE_VALID_SECONDS" ]]  &&  LV_CACHE_VALID_SECONDS=2
    [[ $LV_COMPACT_MODE == 'true' ]]    && LV_SEGMENT_SPACE=" "         || LV_SEGMENT_SPACE="  "

    precache_git

    ## tämä muuttuja säätää zsh:ssä promptin ulkonäköä (apufunktioidensa ohella)
    if [[ $LV_TWO_ROW_MODE == true ]]; then
        PROMPT="$(
            prompt_start
            prompt_cached_git
            prompt_exit_code
            prompt_dir
            prompt_end
        )"
    else
        PROMPT="$(
            prompt_start
            prompt_dir
            prompt_cached_git
            prompt_end
        )"
    fi

    LV_LAST_PWD="$PWD"
    LV_LAST_TIME_CHECKED="$EPOCHSECONDS"
}


function main() {
    export LV_LAST_PWD LV_LAST_TIME_CHECKED LV_CACHED_GIT_PROMPT LV_SEGMENT_SPACE LV_TWO_ROW_MODE

    ## HUOM! Jos näistä halutaan .zshrc:ssä muokattavia, nämä(kin) siirrettävä build_promptiin!
    LV_COLOR_ERROR_BOLD="%{$fg_bold[red]%}"     ## bold punainen
    LV_COLOR_ERROR='%{%F{1}%}'                  ## punainen, (124, 197, 160, 9, 1)
    LV_COLOR_GIT_GOOD='%{%F{41}%}'              ## vihreä (47, 120, 41)
    LV_COLOR_GIT_NEUTRAL='%{%F{86}%}'           ## sinisempi (43, 44, 81, 86)
    LV_COLOR_DOTDOTDOT='%{%F{102}%}'            ## harmaa (244, 247, 102)
    LV_COLOR_DIR_TEXT='%{%F{152}%}'             ## "polun väri", esim joku harmahtava (152, 103, 145, 146)
    LV_COLOR_LAMBDA="%{$fg_bold[white]%}"       ## kirkkaan valkoinen (231, 256)
    LV_COLOR_WARN='%{%F{227}%}'                 ## keltainen (227, 142)
    LV_COLOR_WARNER='%{%F{208}%}'               ## oranssi (208, 130)
    LV_COLOR_PROMPT_NORMAL='%{%F{252}%}'        ## promptimerkin väri normaalisti, valkoinen
    LV_COLOR_USER='%{%F{139}%}'                 ## käyttäjän väri joku hillitty (139, 140, 146)
    LV_COLOR_HOST_NORMAL='%{%F{139}%}'          ## normihostin väri: selkeintä käyttää sama k. käyttäjä!
    LV_COLOR_AT_MACHINE='%{%F{60}%}'            ## "user -->@ host" -väri (60, 61, 69)
    LV_COLOR_HOST_SSH='%{%F{104}%}'             ## hostin väri, jos ssh (141, 103, 104)
    LV_COLOR_PROMPT_GOD='%{%F{220}%}'           ## promptimerkin väri jos olet root, kultainen (226, 220, 227)

    ## esiasetukset (version control system info)
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr "${LV_COLOR_WARN}⋇"
    zstyle ':vcs_info:*' unstagedstr "${LV_COLOR_WARNER}*"
    zstyle ':vcs_info:*' formats '%u%c'
    zstyle ':vcs_info:*' actionformats '%u%c'

    LV_LAST_TIME_CHECKED=-1  ## aluksi ei mitään, oikea arvo asettuu kun zsh ajaa lv_build_prompt oman logiikkansa mukaan

    ## itse suoritus asetetaan zsh:ssä tähän komentoon
    add-zsh-hook precmd lv_build_prompt
}

main
