#!/bin/zsh

arg="$1"
alku="[  "
lopu=" ]"

command -v whereis 1> /dev/null 2> /dev/null \
    && echo -e "$alku whereis $lopu" \
    && whereis $arg
    echo -e "\n"

command -v where 1> /dev/null 2> /dev/null \
    && echo -e "$alku where $lopu" \
    && where $arg
    echo -e "\n"

command -v whence 1> /dev/null 2> /dev/null \
    && echo -e "$alku whence $lopu" \
    && whence $arg
    echo -e "\n"

command -v which 1> /dev/null 2> /dev/null \
    && echo -e "$alku which $lopu" \
    && which $arg
    echo -e "\n"

command -v which-command 1> /dev/null 2> /dev/null \
    && echo -e "$alku which-command $lopu" \
    && which-command $arg
    echo -e "\n"
