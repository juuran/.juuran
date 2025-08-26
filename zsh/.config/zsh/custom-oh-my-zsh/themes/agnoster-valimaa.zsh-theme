## Vähäisiä muokkauksia ja optimointeja hienoon agnoster-teemaan.

CURRENT_BG='NONE'
CURRENT_FG='white' #black

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}


### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols
  
  if [[ $RETVAL -ne 0 ]]; then
    prompt_segment black red "∇"
  else
    prompt_segment black green "∆"
  fi
  
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  if [[ -n "$VIRTUAL_ENV" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    prompt_segment blue black "(${VIRTUAL_ENV:t:gs/%/%%})"
  fi
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$HOST" == "KANALANMANAT" ]]; then
    true  ## ei tehdä toistaiseksi mitään
  elif [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n@%m"
  fi
}

# Dir: current working directory
prompt_dir() {
  local dir
  dir=$(print -P "%3~")
  if [[ "$dir" == "/"* ]] || [[ "$dir" == "~"* ]]; then
    prompt_segment blue $CURRENT_FG '%3~'
  else
    prompt_segment blue $CURRENT_FG '... %3~/'
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  command git rev-parse --is-inside-work-tree &> /dev/null || return  ## nopea poistuminen

  (( $+commands[git] )) || return
  if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=''         # git ikoni
  }
  local ref dirty mode repo_path

  repo_path=$(command git rev-parse --git-dir 2>/dev/null)
  dirty=$(parse_git_dirty)
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref="◈ $(command git describe --exact-match --tags HEAD 2> /dev/null)" || \
  ref="➦ $(command git rev-parse --short HEAD 2> /dev/null)"
  if [[ -n $dirty ]]; then
    prompt_segment yellow black
  else
    prompt_segment green $CURRENT_FG
  fi

  local ahead behind
  ahead=$(command git log --oneline @{upstream}.. 2>/dev/null)
  behind=$(command git log --oneline ..@{upstream} 2>/dev/null)
  if [[ -n "$ahead" ]] && [[ -n "$behind" ]]; then
    PL_BRANCH_CHAR='↔'
  elif [[ -n "$ahead" ]]; then
    PL_BRANCH_CHAR='↪'
  elif [[ -n "$behind" ]]; then
    PL_BRANCH_CHAR='↩'
  fi

  if [[ -e "${repo_path}/BISECT_LOG" ]]; then
    mode=" <B>"
  elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
    mode=" >M<"
  elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
    mode=" >R>"
  fi

  setopt promptsubst
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' get-revision true
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr '⋇'
  zstyle ':vcs_info:*' unstagedstr '*'
  zstyle ':vcs_info:*' formats ' %u%c'
  zstyle ':vcs_info:*' actionformats ' %u%c'
  vcs_info
  echo -n "${${ref:gs/%/%%}/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
}


## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
