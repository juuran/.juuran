#!/bin/bash
pids=""
failures=0

valeAjo() {
  echo -en "\nAjetaan $2."
  for (( i=0; i<=$1; i++)); do
    echo -n "."
    sleep 0.5
  done
  if [ $((RANDOM % 8)) -ne 1 ]
  then  echo "tehty $2"
        exit
  else  echo "feilattu $2"
        exit 1
  fi
}

## Tätä ei nyt tarvita, ehkä koska ajetaan for-luupissa...? Mutta toimisi näin:
## Tämä on sellainen ihmeloitsu, millä saa kaikki ohjelmat tapettua yhdellä ctrl + c :llä
## Ajaa kaikki ohjelmat alishellissä ja vangitaan SIGINT ajamaan kill 0, joka tappaa
## kaikki tuossa alishellissä jostain syystä. Viimeisen tärkeä olla etualalla ja wait
## siihen paras, koska se vain odottaa että muut saman skriptin toiminnot ovat valmiita.
# (trap 'kill 0' SIGINT; prog1 & prog2 & prog3 & wait)

for i in {1..5}; do
  (valeAjo $((RANDOM % 6)) $i ) &
  pids+=" $!"                             ## $! on viimeisimmän uuden taustaprosessin pid
done

## odotetaan että kaikki meni maaliin
for p in $pids; do
        if wait $p; then
                echo "Process $p success"
        else
                exitCode=$?
                echo "Process $p exited with code $exitCode"
                failures=$((failures+1))
        fi
done

wait
if [ $failures -gt 0 ]; then
          echo "Out of all the tasks, $failures failed. Exiting with nonzero status."
          exit 1
  else
          echo "All tasks completed successfully!"
          exit
fi
