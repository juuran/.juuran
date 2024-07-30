#compdef sha-tarkistin.sh

shaNimet='(sha256sum sha512sum sha1sum sha384sum sha224sum)'

_arguments -s \
    '1:fileToCheck:_files' \
    '2::shaToCheck:' \
    '(-h --help)'{-h,--help}'[näyttääpi opasteen eli tienvarsiviitan]' \
    "-s[käytettävän shaSum ohjelman nimi annetaan tämän perään]:shaNimi:($shaNimet)"
