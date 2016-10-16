#! /bin/bash


rm -f old-new-list

old_ifs=$IFS
IFS=:

while read user passwd uid gid fulllname homedir Shell
do
    if read user2 passwd2 uid2 gid2 fullname2 homedir2 Shell2
    then
        if [ $user = $user2 ]
        then
            printf "%s\t%s\t%s\n" $user $uid $uid2 >> old-new-list 
            echo "$user:passwd:$uid2:$gid:$fullname:$homedir:$Shell"
        else
            echo $0: out of sync: $user and $user2 >&2
            exit 1
        fi
    else
        echo $0: no duplicate for $user >&2
        exit 1
    fi
done < dupusers > unique2
IFS=$old_ifs
