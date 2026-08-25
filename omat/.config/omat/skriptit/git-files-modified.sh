#/bin/bash

## Tämän vastauksen oli näemmä syöttänyt Peda.net:in kehittäjä Mikko Rantalainen:
# https://serverfault.com/questions/401437/how-to-retrieve-the-last-modification-date-of-all-files-in-a-git-repository

function main() {
    if [ -z "$1" ]
    then
        git ls-tree -r --name-only HEAD -z | TZ=UTC xargs -0n1 -I_ git --no-pager log -1 --date=iso-local --format="%ad %h _" -- _

    else
        ## en jaksa muistaa mitä tämä IFS setti on, chatgpt:tä tällä kertaa, koska kello paljon
        echo -e '*** lisäargumenteilla (esim. HEAD) näkyy oikein vain "git" kansion juuressa ***\n'
        git diff --name-only -z $@ |
        while IFS= read -r -d '' file; do
            git log -1 --format='%cI  %h' HEAD -- "$file" | tr -d '\n'
            printf '  %s\n' "$file"
        done
    fi
}

main "$@"
