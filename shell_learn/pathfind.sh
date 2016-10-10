#! /bin/bash -
# 
# find in $path, 
# file or directory
# standard output
# error output
# if find all file, return 0
# else if one not find, return !0

# pathfind [--all] [--?] [--help] [--version] envvar pattern

# --all: find all file in path 

# IFS=

OLDPATH="$PATH"
PATH=/bin:/usr/bin

export PATH

error()
{
    echo "$#" 1>&2
    usage_and_exit 1
}

usage()
{
    echo "Usage: $PROGRAM [--all] [--?] [--help] [--version] envvar pattern(s)"
}

usage_and_exit()
{
    usage
    exit $1
}

version()
{
    echo "$PROGRAM version $VERSION"
}

warning()
{
    echo "$#" 1>&2
    EXITCODE=`expr $EXITCODE + 1`
}

all=no
envvar=
EXITCODE=0
PROGRAM=`basename $0`

VERSION=1.0

while test $# -gt 0
do
    case $1 in
        --all | --al | --a | -all | -a )
            all=yes
            ;;
        --help | --hel | --he | --h | '--?' | -help | -hel | -he | -h | '-?' )
            usage_and_exit 0
            ;;
        --version | --versio | --versi | --vers | --ver | --ve | --v | \
        -version | -versio | -versi | -vers | -ver | -ve | -v )
            version
            exit 0
            ;;
        -*)
            error "Unrecognized option: $1"
            ;;
        *)
            break
            ;;
    esac
    shift
done

envvar="$1"
echo envvar: $envvar
test $# -gt 0 && shift
test "x$envvar" = "xPATH" && envvar=OLDPATH
dirpath=`eval echo '${'"$envvar"'}' 2>/dev/null | tr : ' ' `

# dirpath='( '$dirpath' )'
echo dirpath:$dirpath
# check error

if test -z "$envvar"
then
    echo 'test -z "#envvar"'
    error Environment variable missing or empty
elif test "x$dirpath" = "x$envvar"
then
    echo 'test x"$dirpath"............'
    error "Broken sh on this platform: cannot expand $envvar"
elif test -z "$dirpath"
then
    echo 'enpty directory '
    error Empty directory search path
elif test $# -eq 0
then
    echo "test $# -eq"
    exit 0
fi

echo in first for ............



for pattern in "$@"
do
    echo '_____________________________________________'
    echo $pattern
    echo '_____________________________________________'
    result=
    nowpath=$dirpath
    for var in $nowpath
    do
        echo '========================================='
        echo $var/$pattern....
        echo '========================================='
        for file in $var/$pattern
        do
            if test -f "$file"
            then
                result="$file"
                echo result: $result
                test "$all" = "no" && break 2
            fi
        done
    done
    test -z "$result" && warning "$pattern not found"
done

# limit exit state
test $EXITCODE -gt 125 && EXITCODE=125

exit $EXITCODE

