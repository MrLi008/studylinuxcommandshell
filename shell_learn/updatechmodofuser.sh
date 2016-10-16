#! /bin/bash

while read user old new
do
    cd /home/$user
    chown -R $new
done < old-new-list

