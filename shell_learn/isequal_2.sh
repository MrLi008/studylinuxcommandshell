#! /bin/bash
# function declared
equal(){
    case "$1" in
        "$2")
            return 0;
    esac
    return 1;
}

# test euqal function
f=ff
gg=ff
echo `equal $f $gg`
echo $( equal "$1" "$2" ),$?
if [ $? ]
then
    echo "[ $? ] same"
else
    echo "[ $? ] different"
fi

if [ $( equal "$1" "$2" )  ]
then
    echo "same"
else
    echo "different"
fi

