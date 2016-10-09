#! /bin/bash
# head --- print topp n
# head -N file

count=$(echo $1|sed 's/^-//')
shift
sed ${count}q "$@"
