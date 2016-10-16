#! /bin/awk -f
# $1 $2 $3 $4 $5 $6 $7
# user:passwd:uid:gid:long name:homedir:Shell

BEGIN { FS = ":" }

# name[] ----index by name
# uid[]  ----index by uid

# if repeat
{

    if ($1 in name){
        if ($3 in uid){
            ;
        }

        else{
            print name[$1] > "dupusers"
            print $0 > "dupusers"
            delete name[$1]

        # delete the same name, dif uid
            remove_uid_by_name($1)
        }
    }
    else if ($3 in uid){
#       
        print uid[$3] > "dupids"
        print $0 > "dupids"
        delete uid[$3]

        remove_name_by_uid($3)
    } else{
        
        name[$1] = uid[$3] = $0

    }

}


END {
    for (i in name){
        print name[i] > "unique1"

        }
    close("unique1")
    close("dupusers")
    close("dupids")
}

function remove_uid_by_name(n, i, f){

    for (i in uid){
        split(uid[i], f, ":")
        if (f[1] == n){
            delete uid[i]
            break
            }

        }
}

function remove_name_by_uid(id, i, f){
    for (i in name){
        split(name[i], f, ":")
        if (f[3] == id){
            delete name[i]
            break
            }
        }        
}
