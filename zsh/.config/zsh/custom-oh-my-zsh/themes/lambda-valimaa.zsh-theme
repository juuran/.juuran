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
    
    echo -n "%{$fg%}"  ## <- ei sisällä välilyöntiä toisin kuin agnoster!
    [[ -n $2 ]] && echo -n $2
}

# End the prompt, closing any open segments
function prompt_end() {
    ## eri väri jos olet superuser
    [[ $UID -ne 0 ]] && prompt_color="${LV_COLOR_PROMPT_NORMAL}" || prompt_color="${LV_COLOR_PROMPT_GOD}"
    echo -n "%{%k%}%{%f%}${prompt_color}${SEGMENT_SPACE}%{$reset_color%}"
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
    command git rev-parse --is-inside-work-tree &> /dev/null || return  ## nopea poistuminen
    (( $+commands[git] )) || return

    local PL_BRANCH_CHAR PL_STASH_CHAR
    () {
        local LC_ALL="" LC_CTYPE="en_US.UTF-8"
        PL_BRANCH_CHAR=''         # git ikoni, jos haluat
    }
    local ref dirty repo_path mode temp_space

    repo_path=$(command git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(command git symbolic-ref HEAD 2> /dev/null)
    if [[ -n $dirty ]]; then
        prompt_segment ${LV_COLOR_GIT_NEUTRAL} "${SEGMENT_SPACE}"
    else
        prompt_segment ${LV_COLOR_GIT_GOOD} "${SEGMENT_SPACE}"
    fi

    local ahead behind
    ahead=$(command git log --oneline @{upstream}.. 2>/dev/null)
    behind=$(command git log --oneline ..@{upstream} 2>/dev/null)
    if [[ -n "$ahead" ]] && [[ -n "$behind" ]]; then
        PL_BRANCH_CHAR="${LV_COLOR_ERROR} ⇅"
    elif [[ -n "$ahead" ]]; then
        PL_BRANCH_CHAR="${LV_COLOR_GIT_NEUTRAL} ↥"
    elif [[ -n "$behind" ]]; then
        PL_BRANCH_CHAR="${LV_COLOR_GIT_NEUTRAL} ↧"
    fi

    local stashed
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
    [[ $LAMBDA_VALIMAA_COMPACT_MODE == 'true' ]] && SEGMENT_SPACE=" " || SEGMENT_SPACE="  "
    PROMPT='%{%f%b%k%}$(build_prompt) '
}

main
