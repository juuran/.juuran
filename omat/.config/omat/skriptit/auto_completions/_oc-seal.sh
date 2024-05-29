#compdef oc-seal.sh

_get_oc_secrets() {
    if ! $(oc get secrets &> /dev/null); then  ## yhteystarkistus (nopeampi kuin "oc status")
        completionit=("oc_unavailable") ## virhetuloste selkeämpi kun sekin on completion
    else
        IFS=$'\n' completionit=($(oc get secrets --output name | cut -d / -f 2))
    fi
    
    _describe -t output 'secretit' completionit
}

_arguments -s \
    '*:polku:_get_oc_secrets' \
    '(-h --help)'{-h,--help}'[displays help]' \
