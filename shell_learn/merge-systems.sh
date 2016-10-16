#! /bin/bash

sort u1/etc/passwd u2/etc/passwd > mergel

awk -f splitout.awk mergel 
awk -F: '{ print $3 }' mergel | sort -n -u > unique-ids

rm -f old-new-list
old_ifs=$IFS

IFS=:


while read user passwd uid gid fullname homedir Shell
do
    if read user2 passwd2 uid2 gid2 fullname2 homedir2 Shell2
    then 
        if [ $user = $user2 ]
        then 
            printf "%s\t%s\t%s\n" $user $uid $uid2 >> old-new-list
            echo "$user:$passwd:$uid2:$gid:$fullname:$homedir:$Shell"
        else
            echo $0: out sync: $user and $user2 >&2
            exit 1
        fi
    else
        echo $0: no duplicate for $user >&2
        exit 1
    fi
done < dupusers > unique2

IFS=$old_ifs

count=$(wc -l < dupids)

set -- $(newuids.sh -c $count unique-ids)
IFS=:
while read user passwd uid gid fullname homedir Shell
do
    newuid=$1
    shift
    echo "$user:$passwd:$newuid:$gid:$fullname:$homedir:$Shell"

    printf "%s\t%s\t%s\n" $user $uid $newuid >> old-new-list 
done < dupids > unique3
IFS=$old_ifs 

sort -k 3 -t : -n unique[123] > final.password

while read user old new 
do
    echo "find / -user $user -print | xargs chown $new "

done < old-new-list > chown-files 

chmod +x chown-files
rm mergel unique[123] dupusers dupids unique-ids old-new-list 
