# ZSH Theme - Preview: https://i.gyazo.com/8becc8a7ed5ab54a0262a470555c3eed.png
local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

prompt_dir() {
  local dir; dir=$(print -P "%3~")
  if [[ "$dir" == "/"* ]] || [[ "$dir" == "~"* ]]; then
    print -P '%3~'
  else
    print -P '... %3~'
  fi
}

#PROMPT='%{$fg[green]%}%~%{$reset_color%} $(ruby_prompt_info) $(git_prompt_info)%{$reset_color%}%B$%b '
PROMPT='%{$fg[green]%}$(prompt_dir)%{$reset_color%} $(ruby_prompt_info) $(git_prompt_info)%{$reset_color%}%B$%b '
RPROMPT="${return_code}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="› %{$reset_color%}"


ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}‹"
ZSH_THEME_RUBY_PROMPT_SUFFIX="› %{$reset_color%}"
