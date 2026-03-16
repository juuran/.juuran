#!/bin/zsh

function really_though_where() {
    local arg vihrea noColor
    arg="$1"
    vihrea='\033[0;32m'
    noColor='\033[0;37m'

    for cmd in whatis alias whereis where whence which; do
        command -v $cmd 1> /dev/null 2> /dev/null || continue

        echo -e "${vihrea}[ $cmd ]${noColor}"
        $cmd $arg
        echo ""
    done
}
