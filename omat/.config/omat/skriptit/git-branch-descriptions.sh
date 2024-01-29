#!/bin/bash
## ilman tarkkaa "--format" määrittelyä tulostaa kaikenlaista sontaa pätkäistäessä:
##     echo $BRANCHES
## koska, sillä tavalla syöte tulee bufferiin syystä tai toisesta. Tietysti voisi
## tehdä myös muotoilemattoman / katkaisemattoman echotuksen:
##     echo "$BRANCHES"
## mutta for ei tue monirivistä käsittelyä, vain välilyönnillä erottelua, joten ei
## se kovin nätiltä näyttäisi sekään.

BRANCHES=$(git branch --format="%(refname:short)")
CURRENT=$(git branch --show-current)

NO_COLOR='\033[0m'
GREEN=$(tput setaf 76)

PAD="                                                                             "  ## (parempi liikaa kuin liian vähän)
BRANCH_MAX_LENGTH=90
BRANCH_LENGTH=$(( $(tput cols) / 2 ))
[ $BRANCH_LENGTH -gt $BRANCH_MAX_LENGTH ] && BRANCH_LENGTH=$BRANCH_MAX_LENGTH
## echo "tput cols=$(tput cols)  BRANCH_LENGTH=$BRANCH_LENGTH "  ## debug
DESCR_LENGTH=$(( $(tput cols) -BRANCH_LENGTH -4))  ## hankkii maksimileveyden

for branch in $BRANCHES
    do
        description=$(git config branch.$branch.description)
        padded_branch="${branch}${PAD}"
        truncated_branch_name="${padded_branch:0:BRANCH_LENGTH}"

        if [ ${#description} -gt $DESCR_LENGTH ]
            then truncated_descr="${description:0:$((DESCR_LENGTH - 4))}..."
            else truncated_descr="$description"
        fi

        formatted_line="$truncated_branch_name  $truncated_descr"
        if [ $branch = $CURRENT ]
            then echo -e "* ${GREEN}${formatted_line}${NO_COLOR}"
            else echo -e "  $formatted_line"
        fi
    done

## Merkinnöistä: Yhdistelmä ${} tarkoittaa vain muuttujan korvaamista, kun taas
## $() on lyhenne `command` komennolle, jolla suoritetaan jokin ohjelma, ja
## $(()) taas tarkoittaa aritmeettisen operaation auki laskemista. Hakasulkujen
## sisällä # tarkoittaa "anna stringin pituus", := olisi korvaa jos tyhjä. Näitä
## löytyy kätevästi bashin manuaalista.
