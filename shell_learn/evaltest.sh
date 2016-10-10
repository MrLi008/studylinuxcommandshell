#! /bin/bash 

envvar="$1"
echo $envvar

dirpath=`eval echo '${'"$envvar"'}' 2>/dev/null | tr : ' ' `
echo dirpath:$dirpath
for v in $dirpath
do
    for var in $dirpath #`eval echo '${'"$envvar"'}' 2>/dev/null | tr : ' ' `
    do
        echo $var,$v
    done
done
echo end...

