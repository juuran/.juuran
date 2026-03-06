#!/bin/zsh

function really_though_where() {
    local arg alku lopu noColor ehree
    arg="$1"
    alku="[ "
    lopu=" ]"
    
    noColor='\033[0;37m'
    ehree='\033[2;92m'

    for cmd in whatis alias whereis where whence which which-command; do
        if command -v $cmd 1> /dev/null 2> /dev/null; then
            echo -e "${ehree}$alku $cmd $lopu${noColor}"
            $cmd $arg
            echo -e ""
        fi
    done
}
