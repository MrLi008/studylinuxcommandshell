#! /bin/bash

count=$(wc -l < dupids)

#
set -- $(newuids.sh -c $count unique-ids)

IFS=:
while read user passwd uid gid fullname homedir Shell
do
    newuid=$1
    shift
    echo "$user:$passwd:$newuid:$gid:$fullname:$homedir:$Shell"

    printf "%s\t%s\t%s\n" $user $uid $newid >> old-new-list
done < dupids > unique3

IFS=$old_ifs

