#! /bin/bash

# This is a test about for<Plug>(neosnippet_expand)
for f in outputofls-l.txt
do
    tr -d '\r' < $f >> big-Unix-file.txt
done

