## olen koittanut värejä tähän, mutta bugeja on eikä ole sen väärti
## (ei mm. toimi hyvin yhteen auto completen kanssa)

prompt_dir() {
  local dir; dir=$(print -P "%3~")
  if   [[ "$dir" == "/"* ]]; then
    print -P '%3~'
  elif [[ "$dir" == "~"* ]]; then
    print -P '%3~/'
  else
    print -P '... %3~/'
  fi
}

PROMPT='λ $(prompt_dir) $(git_prompt_info)%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
