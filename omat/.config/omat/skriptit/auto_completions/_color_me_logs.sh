#compdef color-me-logs.sh

modeSelections='( default\:"the default setting, no need to insert it"  holodeck\:"formatting for holodeck"  typical\:"a typical formatting used outside EESSI projects"  liberty\:"formatting used by open liberty server by default" )'
_arguments : \
    "-m[select mode]:mode:($modeSelections)" \
    '(-h --help)'{-h,--help}'[display help]'
