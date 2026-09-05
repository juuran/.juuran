#compdef color-me-logs.sh

if [[ -n "$ZSH_VERSION" ]]; then
    ## zsh

    modeSelections='( default\:"the default setting, no need to insert it"  holodeck\:"formatting for holodeck"  typical\:"a typical formatting used outside EESSI projects"  liberty\:"formatting used by open liberty" rpi\:"formatting used by me in rpi script" ocp-build\:"formatting used kela ocp build" )'
    _arguments : \
        "-m[select mode]:mode:($modeSelections)" \
        '(-h --help)'{-h,--help}'[display help]'

else
    ## bash

    setCompletion() {
        completions="$1"
        COMPREPLY=($(compgen -W "$completions" -- "${COMP_WORDS[$COMP_CWORD]}"))
    }

    function _color_me_logs() {
        local currentArgIndex="$COMP_CWORD"
        local currentWord=${COMP_WORDS[$currentArgIndex]}
        local previousWord=${COMP_WORDS[$((currentArgIndex - 1))]}

        if [[ "$previousWord" == "--" ]]; then
            setCompletion "--help"
        elif [[ "$previousWord" == "--help" ]] || [[ "$previousWord" == "-h" ]]; then
            return

        elif [[ "$currentArgIndex" -eq 1 ]]; then
            setCompletion "-m -h --help"
        elif [[ "$currentArgIndex" -eq 2 ]]; then
            if [[ "$previousWord" == "-m" ]]; then
                setCompletion "default holodeck typical liberty rpi ocp-build"
            fi
        fi
    }

    ## tällä tavoin toimii kutsuttaessa sekä koko nimellä (*.sh) että aliaksena
    complete -o nosort -F _color_me_logs color-me-logs
    complete -o nosort -F _color_me_logs color-me-logs.sh

fi
