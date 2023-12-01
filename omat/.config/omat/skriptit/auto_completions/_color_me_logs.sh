#compdef color-me-logs.sh

modeSelections='( default\:"the default setting, no need to insert it"  holodeck\:"formatting for holodeck"  typical\:"a typical formatting used outside EESSI projects" )'
_arguments : "-m:mode:($modeSelections)"
