#compdef git-pull-all.sh

_arguments -s \
    '(-h --help)'{-h,--help}'[display help]' \
    '-p[parallel; runs in parallel but with unclear logs]' \
    '-f[fetch only (using --all --prune) instead of pull (fetch + merge)]' \
    '-d[do; can be used for any custom commands and is run in all subdirectories]' \
    '-s[skips the path specified]'
    