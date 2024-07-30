#compdef g-g-g-grep.sh

_arguments -s \
    '1:hakutermi:' \
    '*:polku:_files' \
    '(-h --help)'{-h,--help}'[display help]' \
    '-i[ignore case off, makes case significant]' \
    '-l[number of context lines to show before and after]' \
    '-E[arguments are interpreted regular expressions (ERE)]' \
    '-d[default "--recursive" is changed into "--dereference-recursive"]' \
    '-r[turns all recursion off]' \
    '-c[compressed files are read using zgrep, disables recursion]' \
    