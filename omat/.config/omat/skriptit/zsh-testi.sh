#!/bin/zsh

echo "Karmeaa zsh-spesifistä paskaa tulossa...."
typeset -Z 5 j
    for ((i=0; i<10; i++)); do
      # <some command> <formatted string with i>
      j=$i; echo "part-$j" # use $j here for sure the effects of below 2 lines
      echo "$(printf "part-%05d" $i)"
      echo "part-${(l:5::0:)j}"
    done
