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

color_error_bold="%{$fg_bold[red]%}"      ## bold punainen
color_error="%{${(%):-"%F{1}"}%}"         ## punainen, (124, 197, 160, 9, 1)
color_git_good="%{${(%):-"%F{41}"}%}"     ## vihreä (47, 120, 41)
color_git_neutral="%{${(%):-"%F{43}"}%}"  ## sinisempi (43, 44, 81)
color_dotdotdot="%{${(%):-"%F{102}"}%}"   ## harmaa (244, 247, 102)
color_dir_text="%{${(%):-"%F{152}"}%}"    ## "polun väri", esim joku harmahtava (152, 103, 145, 146)
color_lambda="%{$fg_bold[white]%}"        ## kirkkaan valkoinen (231, 256)
color_warn="%{${(%):-"%F{227}"}%}"        ## keltainen (227, 142)
color_warner="%{${(%):-"%F{208}"}%}"      ## oranssi (208, 130)
color_god="%{${(%):-"%F{226}"}%}"         ## väri jos olet root, kultainen (226)
color_context="%{${(%):-"%F{139}"}%}"     ## "hostin nimi", joku hillitty (140, 146, 139)


# Begin a segment
# Takes an argument: foreground. Can be "default".
prompt_segment() {
  local fg
  if [[ $1 == "default" ]] || [[ -z "$1" ]]; then
    fg="%f"
  else
    fg="$1"
  fi
  
  echo -n "%{$fg%}"  ## <- ei sisällä välilyöntiä toisin kuin agnoster!
  [[ -n $2 ]] && echo -n $2
}

# End the prompt, closing any open segments
prompt_end() {
  local prompt_symbol prompt_color
  prompt_symbol=" ❯"
  ## eri väri jos olet superuser
  [[ $UID -eq 0 ]] && prompt_color="${color_god}" || prompt_color="${color_lambda}"
  echo -n "%{%k%}%{%f%} ${prompt_color}${prompt_symbol}%{$reset_color%}"
}


### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Status:
# - was there an error
prompt_status_context() {
  if [[ $RETVAL -eq 0 ]]; then
    prompt_segment ${color_lambda} "λ"
  else
    prompt_segment ${color_error_bold} "λ"
  fi

  if [[ "$HOST" == "KANALANMANAT" ]]; then
    true  ## ei tehdä mitään
  else
    prompt_segment ${color_context} "  %n@%m "
  fi
}

# Dir: current working directory
prompt_dir() {
  local dir; dir=$(print -P "%3~")
  if [[ "$dir" == "~"* ]]; then
    prompt_segment ${color_dir_text} ' %3~/'
  elif [[ "$dir" == "/"* ]]; then
    prompt_segment ${color_dir_text} ' %3~'
  else
    prompt_segment default "${color_dotdotdot} … ${color_dir_text}%3~/"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  command git rev-parse --is-inside-work-tree &> /dev/null || return  ## nopea poistuminen
  (( $+commands[git] )) || return
  
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=''         # git ikoni, jos haluat
  }
  local ref dirty repo_path mode

  repo_path=$(command git rev-parse --git-dir 2>/dev/null)
  dirty=$(parse_git_dirty)
  ref=$(command git symbolic-ref HEAD 2> /dev/null)
  if [[ -n $dirty ]]; then
    prompt_segment ${color_git_neutral} '  '
  else
    prompt_segment ${color_git_good} '  '
  fi

  local ahead behind
  ahead=$(command git log --oneline @{upstream}.. 2>/dev/null)
  behind=$(command git log --oneline ..@{upstream} 2>/dev/null)
  if [[ -n "$ahead" ]] && [[ -n "$behind" ]]; then
    PL_BRANCH_CHAR="${color_error} ⇅"
  elif [[ -n "$ahead" ]]; then
    PL_BRANCH_CHAR="${color_git_neutral} ↥"
  elif [[ -n "$behind" ]]; then
    PL_BRANCH_CHAR="${color_git_neutral} ↧"
  fi

  if [[ -e "${repo_path}/BISECT_LOG" ]]; then
    mode="${color_git_neutral} <B>" 
  elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
    mode="${color_git_neutral} >M<"
  elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
    mode="${color_error} >R>"
  fi

  setopt promptsubst
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' get-revision true
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr "${color_warn}⋇"
  zstyle ':vcs_info:*' unstagedstr "${color_warner}*"
  zstyle ':vcs_info:*' formats ' %u%c'
  zstyle ':vcs_info:*' actionformats ' %u%c'
  vcs_info
  echo -n "${${ref:gs/%/%%}/refs\/heads\//}${vcs_info_msg_0_%% }${PL_BRANCH_CHAR}${mode}"
}


## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status_context
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
