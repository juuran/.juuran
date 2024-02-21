#compdef g-g-g-grep.sh

_arguments -s \
    '1:hakutermi:' \
    '2::polku:_files -/ -g "." -g ".."' \
    '(-h --help)'{-h,--help}'[display help]' \
    '-i[ignore case off, makes case significant]' \
    '-E[arguments are interpreted regular expressions (ERE)]' \
    '-d[default "--recursive" is changed into "--dereference-recursive"]' \
    '-r[turns all recursion off]' \
    '-c[compressed files are read using zgrep, disables recursion]' \
    