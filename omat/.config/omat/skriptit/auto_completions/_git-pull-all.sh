#compdef git-pull-all.sh

_arguments -s \
    '(-h --help)'{-h,--help}'[display help]' \
    '-p[parallel, runs in parallel but with more complicated logs]' \
    '-f[fetch only (using --all --prune) instead of pull (fetch + merge)]' \
    '-d[do, can be used for custom commands, starting without 'git']' \
    '-s[skip, the path specified]'
    