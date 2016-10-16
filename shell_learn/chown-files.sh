#! /bin/bash

while read user old new
do
    echo "find / -user $user -print | xargs chown $new"
done < old-new-list > chown-files

chmod +x chown-files 

rm mergel unique[123] dupusers dupids unique-ids old-new-list 

