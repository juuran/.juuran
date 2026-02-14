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
function prompt_segment() {
    fg="$1"
    msg="$2"

    echo -n "%{$fg%}${msg}"
}

# End the prompt, closing any open segments
function prompt_end() {
    ## eri väri jos olet superuser
    [[ $UID -ne 0 ]] && prompt_color="${LV_COLOR_PROMPT_NORMAL}" || prompt_color="${LV_COLOR_PROMPT_GOD}"
    echo -n "%{%k%}%{%f%}${prompt_color}${SEGMENT_SPACE}❯%{$reset_color%}"
}


### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Status:
# - was there an error
function prompt_status_context() {
    if [[ $RETVAL -eq 0 ]]; then
        prompt_segment ${LV_COLOR_LAMBDA} "λ%{$reset_color%}"
    else
        prompt_segment ${LV_COLOR_ERROR_BOLD} "λ%{$reset_color%}"
    fi
    
    prompt_segment ${LV_COLOR_CONTEXT} "${SEGMENT_SPACE}%n@%m"
}

# Dir: current working directory
function prompt_dir() {
    dir=$(print -P "%3~")

    if [[ "$dir" == "~"* ]]; then
        prompt_segment ${LV_COLOR_DIR_TEXT} "${SEGMENT_SPACE}%3~/"
    elif [[ "$dir" == "/"* ]]; then
        prompt_segment ${LV_COLOR_DIR_TEXT} "${SEGMENT_SPACE}%3~"
    else
        prompt_segment "${SEGMENT_SPACE}${LV_COLOR_DOTDOTDOT}…${LV_COLOR_DIR_TEXT}/%3~/"
    fi
}

# Git: branch/detached head, dirty & stashed status
function prompt_git() {
    local repo_path
    repo_path=$(command git rev-parse --git-dir 2>/dev/null) || return  ## nopea poistuminen

    local ref dirty 
    dirty=$(parse_git_dirty)
    ref=$(command git symbolic-ref HEAD 2> /dev/null)
    if [[ -n $dirty ]]; then
        prompt_segment ${LV_COLOR_GIT_NEUTRAL} "${SEGMENT_SPACE}"
    else
        prompt_segment ${LV_COLOR_GIT_GOOD} "${SEGMENT_SPACE}"
    fi

    local ahead behind PL_BRANCH_CHAR
    ahead=$(command git log --oneline @{upstream}.. 2>/dev/null)
    behind=$(command git log --oneline ..@{upstream} 2>/dev/null)
    if [[ -n "$ahead" ]] && [[ -n "$behind" ]]; then
        PL_BRANCH_CHAR="${LV_COLOR_ERROR} ⇅"
    elif [[ -n "$ahead" ]]; then
        PL_BRANCH_CHAR="${LV_COLOR_GIT_NEUTRAL} ↥"
    elif [[ -n "$behind" ]]; then
        PL_BRANCH_CHAR="${LV_COLOR_GIT_NEUTRAL} ↧"
    fi

    local stashed PL_STASH_CHAR mode temp_space
    stashed=$(git stash list)
    [[ -n "$stashed" ]] && PL_STASH_CHAR="${LV_COLOR_GIT_NEUTRAL} ⚹"

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
        [[ $COMPACT_MODE == 'true' ]] && temp_space="" || temp_space=" "
        mode="${temp_space}${LV_COLOR_GIT_NEUTRAL}<B>" 
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
        mode="${temp_space}${LV_COLOR_GIT_NEUTRAL}>M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
        mode="${temp_space}${LV_COLOR_ERROR}>R>"
    fi

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
    echo -n "${${ref:gs/%/%%}/refs\/heads\//}${vcs_info_msg_0_%% }${PL_BRANCH_CHAR}${PL_STASH_CHAR}${mode}"
}

## Main prompt
function build_prompt() {
    RETVAL=$?
    prompt_status_context
    prompt_dir
    prompt_git
    prompt_end
}


function main() {
    LV_COLOR_ERROR_BOLD="%{$fg_bold[red]%}"         ## bold punainen
    LV_COLOR_ERROR="%{${(%):-"%F{1}"}%}"            ## punainen, (124, 197, 160, 9, 1)
    LV_COLOR_GIT_GOOD="%{${(%):-"%F{41}"}%}"        ## vihreä (47, 120, 41)
    LV_COLOR_GIT_NEUTRAL="%{${(%):-"%F{43}"}%}"     ## sinisempi (43, 44, 81)
    LV_COLOR_DOTDOTDOT="%{${(%):-"%F{102}"}%}"      ## harmaa (244, 247, 102)
    LV_COLOR_DIR_TEXT="%{${(%):-"%F{152}"}%}"       ## "polun väri", esim joku harmahtava (152, 103, 145, 146)
    LV_COLOR_LAMBDA="%{$fg_bold[white]%}"           ## kirkkaan valkoinen (231, 256)
    LV_COLOR_WARN="%{${(%):-"%F{227}"}%}"           ## keltainen (227, 142)
    LV_COLOR_WARNER="%{${(%):-"%F{208}"}%}"         ## oranssi (208, 130)
    LV_COLOR_PROMPT_NORMAL="%{${(%):-"%F{251}"}%}"  ## promptimerkin väri normaalisti, valkoinen
    LV_COLOR_PROMPT_GOD="%{${(%):-"%F{226}"}%}"     ## promptimerkin väri jos olet root, kultainen (226)
    LV_COLOR_CONTEXT="%{${(%):-"%F{139}"}%}"        ## "hostin nimi", joku hillitty (140, 146, 139)
    
    [[ $LAMBDA_VALIMAA_COMPACT_MODE == 'true' ]] && SEGMENT_SPACE=" " || SEGMENT_SPACE="  "
    PROMPT='%{%f%b%k%}$(build_prompt) '
}

main
