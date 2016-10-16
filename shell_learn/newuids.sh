#! /bin/sh -

# newuids ---- print one or more uid which unused
# Grammar:
#       newuids [-c N] list-of-ids-file
# -c N
count=1

# analysis 
#
while getopts "C:" opt
do
    case $opt in
        c)
            count=$OPTARG
            ;;
    esac
done

shift $(($OPTIND -l))
IDFILE=$1

awk -v count=$count '
BEGIN {
    for (i = 1; getline id > 0; i++){
        uidlist[i] = id

    }
    totalids = i

    for (i = 2; i <= totalids; i++){
        if (uidlist[i-1] != uidlist[i]){
            for (j = uidlist[i-1] + 1; j < uidlist[i]; j++){
                print j
                if (--count == 0)
                    exit
            }
        }
    }
}
' $IDFILE

