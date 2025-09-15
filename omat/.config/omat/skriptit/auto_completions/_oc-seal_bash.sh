#/usr/bin/env bash

set_completion() {
    completions="$1"
    # shellcheck disable=SC2207  ## seuraavan rivin pitääkin splitata merkit
    COMPREPLY=($(compgen -W "$completions" -- "${COMP_WORDS[$COMP_CWORD]}"))
}

_get_oc_secrets() {
    if ! $(oc get secrets &> /dev/null); then  ## yhteystarkistus (nopeampi kuin "oc status")
        set_completion "oc_unavailable"  ## virhetuloste selkeämpi kun sekin on completion
    else
        completionit=$(oc get secrets --output name | cut -d / -f 2)
        set_completion "$completionit"
    fi
}

complete -o nosort -F _get_oc_secrets oc-seal
