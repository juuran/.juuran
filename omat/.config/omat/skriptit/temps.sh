#!/bin/bash
sleptiem=5  ## oikea nukkuma-aika on tämä plus tyyliin 4, mikä tulee topista
uptiem=1

if [ -n "$*" ]; then
  echo "Ohjelma ei tue argumentteja!"
  exit 1
fi

show_temps() {
  local gpuTemp=$(vcgencmd measure_temp)
  ## Näyttäisivat olevan tismalleen sama arvo aina, paitsi joskus mittaushetken virheen takia
  # cpuTempRaw=$(</sys/class/thermal/thermal_zone0/temp)
  # cpuTemp="temp=$((cpuTempRaw/1000)).$(((cpuTempRaw%1000)/100))'C"
  local clkRaw=$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
  local clk="$((clkRaw/1000000)).$(((clkRaw%1000000)/100000))GHz"

  ## Napataan top:lta kahdesta "batch" arvosta vain jälkimmäinen, koska ensimmäisessä näkyy
  ## topin käynnistysaika, mikä vääristää cpu:n käyttöä yllättävän paljon (5-8 prosenttia)
  local topRaw="$(top -bn 2 | head -n 6)"
  local cpuUsage="$(echo "$topRaw" | grep --color=never -i %cpu | grep -oE -e '^.*id' )"
  local tasks="$(echo "$topRaw" | grep --color=never -i tasks)"
  uptime="$(echo "$topRaw" | grep --color=never -i 'top - ')"
  mem="$(echo "$topRaw" | grep --color=never -i 'mib mem')"
  swap="$(echo "$topRaw" | grep --color=never -i 'mib swap')"
  local dateTime="$(date +%d.%m.%Y\ %H:%M:%S)"
  echo "$dateTime  [$gpuTemp]   [clock=$clk]   [$cpuUsage]   [$tasks]"
}

valiaikaTieto() {
  echo "---------- Väliaikatietoja -----------"
  echo "    uptime:         [$uptime]"
  echo "    muistinkäyttö:  [$mem]"
  echo "    swapin käyttö:  [$swap]"
  echo "--------------------------------------"
}

echo "    -- Näytetään rpi:n sisäiset lämpötilat, kellotaajuus ja cpu:n käyttö --" 
echo "                     (mittaus lopetetaan painamalla ctrl + c)"
echo

i=1
while true
do
  show_temps
  [[ $((i % uptiem)) == 0 ]] && valiaikaTieto
  sleep $sleptiem
  i=$((i+1))
done
