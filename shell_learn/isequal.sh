#! /bin/bash

# function declared
equal(){
    case "$1" in
        "$2")
            return 0;
            ;;
    esac
    return 1;
}

# test eqaul function
a=ff
b=ff
equal "$a" "$b"
if [ $? ]
then
    echo "This is same....",$a,"==",$b
else
    echo "This is not same....."
fi

