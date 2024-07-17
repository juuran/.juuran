#!/bin/bash

## defaultit
SLEEPING=2
RUNNING=false
GPU=false
TOP=true
MORE_INFO=false

for arg in "$@"; do
    [ "$arg" == "run" ]         && RUNNING=true
    [ "$arg" == "gpu" ]         && GPU=true
    [ "$arg" == "notop" ]       && TOP=false
    [ "$arg" == "more_info" ]   && MORE_INFO=true
done

show_gpu_stats() {
    ## netistä napattu tapa tehdä tämä ( https://forums.raspberrypi.com/viewtopic.php?t=321461 )
        ## lista vcgencmd arvoista ( https://elinux.org/RPI_vcgencmd_usage )
        local coreV=$(vcgencmd measure_volts | cut -f2 -d '=' | sed 's/000//')                          ## gpu core voltage
        # local arm=$(vcgencmd measure_clock arm | awk -F"=" '{printf ("%0.0f",$2/1000000.0); }')       ## arm cpu - tämä tehdään jo!
        local core=$(vcgencmd measure_clock core | awk -F"=" '{printf ("%0.0f",$2/1000000.0); }')       ## GPU core clock!
        local h264=$(vcgencmd measure_clock h264 | awk -F"=" '{printf ("%0.0f",$2/1000000.0); }')       ## h264 encoding
        local v3d=$(vcgencmd measure_clock v3d | awk -F"=" '{printf ("%0.0f",$2/1000000.0); }')         ## 3d block speed
        # emmcClk=$(vcgencmd measure_clock emmc | awk -F"=" '{printf ("%0.0f",$2/1000000.0); }')        ## sd card interface
        # local pixl=$(vcgencmd measure_clock pixel | awk -F"=" '{printf ("%0.0f",$2/1000000.0); }')    ## pixel?
        local thr=$(perl -e "printf \"%19b\n\", $(vcgencmd get_throttled | cut -f2 -d=)")               ## netistä, en opetellut perliä... ;)

        local gpuRaw="$(vcgencmd get_mem arm && vcgencmd get_mem gpu)"
        local gpuRaw2="$(echo "$gpuRaw" | tr '\n' ' ')"
        GPU_STATS="   [${gpuRaw2:0:-1}, voltage=$coreV, thrtl=$thr]   [clocks MHz: gpuCore=$core, h264=$h264, v3d=$v3d]"
}

show_temps() {
    local gpuTemp="   [$(vcgencmd measure_temp)]"
    ## Näyttäisivat olevan tismalleen sama arvo aina, paitsi joskus mittaushetken virheen takia
    # cpuTempRaw=$(</sys/class/thermal/thermal_zone0/temp)
    # cpuTemp="temp=$((cpuTempRaw/1000)).$(((cpuTempRaw%1000)/100))'C"
    local clkRaw=$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    local clk="   [clock=$((clkRaw/1000000)).$(((clkRaw%1000000)/100000))GHz]"

    local cpuUsage=""
    local tasks=""
    if [ $TOP == true ]; then
        ## Napataan top:lta kahdesta "batch" arvosta vain jälkimmäinen, koska ensimmäisessä näkyy
        ## topin käynnistysaika, mikä vääristää cpu:n käyttöä yllättävän paljon (5-8 prosenttia)
        local topRaw="$(top -bn 2 | head -n 6)"
        cpuUsage="   [$(echo "$topRaw" | grep --color=never -i %cpu | grep -oE -e '^.*id' )]"
        tasks="   [$(echo "$topRaw" | grep --color=never -i tasks)]"
        UPTIME="$(echo "$topRaw" | grep --color=never -i 'top - ')"
        MEM="$(echo "$topRaw" | grep --color=never -i 'mib mem')"
        SWAP="$(echo "$topRaw" | grep --color=never -i 'mib swap')"
    fi

    GPU_STATS=""
    [ $GPU == true ] && show_gpu_stats

    DATETIME="$(date +%d.%m.%Y\ %H:%M:%S)"
    echo "${DATETIME}${gpuTemp}${clk}${cpuUsage}${tasks}${GPU_STATS}"
}

show_more_info() {
    echo "---------- Väliaikatietoja -----------"
    echo "    uptime:           [$UPTIME]"
    echo "    muistin käyttö:   [$MEM]"
    echo "    swapin käyttö :   [$SWAP]"
    echo "    RAID1:n kunto :   coming soon..."  ## TODO: tulossa on, mutta järki käteen (ja ostoksille!)
    echo "    prismien kunto:   ehkä, ehkä, ehkä tulee..."
    echo "--------------------------------------"
}


run_show_temps() {
    if [ $RUNNING == false ]; then
        show_temps
        [ $MORE_INFO == true ] && show_more_info
        exit 0
    fi

    i=1
    while true
    do
        show_temps
        if [[ $((i % 10)) == 0 ]]; then
            [ $MORE_INFO == true ] \
                && show_more_info \
                || echo "--------------------------------------"
        fi
        sleep $SLEEPING
        i=$((i+1))
    done
}

run_show_temps
