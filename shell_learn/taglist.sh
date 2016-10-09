cat $1 |
tr ' {}[]()' '_' |
tr ':' '=' |
sed 's:<:\n<:g' |
sed 's:<.*>::g' |
sort |
uniq -c |
sort -k2,1
