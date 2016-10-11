#! /bin/bash
#
#
#
# In parallel processing, construct one or more packages
# on one or more hosts

#
# Grammar:
# build-all [ --? ]
#           [ --all "..." ]
#           [ --cd "..." ]
#           [ --check "..." ]
#           [ --configure "..." ]
#           [ --environment "..." ]
#           [ --help ]
#           [ --logdirectory dir ]
#           [ --on "{user@}host[:dir][,envfile]..." ]
#           [ --source "dir..." ]
#           [ --userhosts "file(s)" ]
#           [ --version ]
#           package(s)
# Optional initial file
#       $HOME/.build/directories    list of source directories
#       $HOME/.build/userhosts      list of [user@]host[:dir][,envfile]

IFS='
        '


# set PATH
PATH=/usr/local/bin:/bin:/usr/bin
export PATH

# set access
UMASK=002
umask $UMASK

# initial variable
ALLTARGETS=                 # Make target
altlogdir=                  # Another location for the log file
altsrcdirs=                 # Another location of the source file
ALTUSERHOSTS=               # List additional host files
CHECKTARGETS=check          # Name of target make for the execution of the package test
CONFIGUREDIR=               # Configuration script sub directory
CONFIGUREFLAGS=             # Special flag for the configuration program
LOGDIR=                     # Local directory to keep log files
userhosts=                  # Additional build host specified on the command line


# build-all initial catalog
BUILDHOME=$HOME/.build

# begin of build-all 
BUILDBEGIN=./.build/begin
# end of build-all 
BUILDEND=./.build/end

# set exit code
EXITCODE=0

# no extra environment
EXTRAENVIRONMENT=

# program name
PROGRAM=`basename $0`
# version number
VERSION=1.0

# time date flags
DATEFLAGS="+%Y.%m.%d.%H.%M.%S"

# secure Shell
SCP=scp
SSH=ssh

# close channel
SSHFLAGS=${SSHFLAGS--x}

# comment
STRIPCOMMENTS='sed -e s/#.*$//'

# filter
INDENT="awk '{ print \"\t\t\t\" \$0 }'"
JOINLINES="tr '\n' '\040'"

# two optional initial file
defaultdirectories=$BUILDHOME/directories
defaultuserhosts=$BUILDHOME/userhosts

# set source list catalog 
SRCDIRS="`$STRIPCOMMENTS $defaultdirectories 2> /dev/null`"


# 
test -z "$SRCDIRS" && \
    SRCDIRS="
            .
            /usr/local/src
            /usr/local/gnu/src
            $HOME/src
            $HOME/gnu/src
            /tmp
            /usr/tmp
            /var/tmp
        "

while test $#,-gt 0
do
    case $1 in
        --all | --al | --a | -all | -al | -a )
            shift
            ALLTARGETS="$1"
            ;;
        --cd | -cd )
            shift
            CONFIGURE="$1"
            ;;
        --check | --chec | --ch | -check | -chec | -che | -ch )
            shift
            CHECKTARGETS="$1"
            ;;

        --configure | --configur | --configu | --config | --confi | \
            --conf | --con | --co | \
            -configure | -configur | -configu | -config | -confi | \
            -conf | -con | -co )
            shift
            CONFIGUREFLAGS="$1"
            ;;

        --environment | --environmen | --environme | --environm | --environ | \
            --enviro | --envir | --envi | --env | --en | --e | \
            -environment | -environmen | -environme | -environm | -environ | \
            -enviro | -envir | -envi | -env | -en | -e )
            shift
            EXTRAENVIRONMENT="$1"
            ;;
        --help | --hel | --he | --h | '--?' | -help | -hel | -he | -h | '-?' )
            usage_and_exit 0
            ;;

        --logdirectory | --logdirector | --logdirecto | --logdirect | --logdirec | \
            --logdire | --logdir | --logdi | --logd | --log | --lo | --l | \
            -logdirectory | -logdirector | -logdirecto | -logdirect | -logdirec | \
            -logdire | -logdir | -logdi | -logd | -log | -lo | -l )
            shift
            altlogdir="$1"
            ;;
        --on | --o | -on | -o )
            shift
            usrhosts="$userhosts $1"
            ;;
        --source | --sourc | --sour | --sou | --so | --s | -source | -sourc | -sour | \
            -sou | -so | -s )
            shift altsrcdirs="$altsrcdirs $1"
            ;;
        --userhosts | --userhost | --userhos | --userho | --userh | --user | --use | --us | --u | \
            -userhosts | -userhost | -userhos | 0userho | -userh | -user | -use | -us | -u )
            shift
            set_userhosts $1
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



# send email
for MAIL in /bin/mailx /usr/bin/mailx /usr/sbin/mailx /usr/ucb/mailx \
            /bin/mail /usr/bin/mail
do
    test -x $MAIL && break
done
test -x $MAIL || error "Cannot find mail client"


SRCDIRS="$altsrcdirs $SRCDIRS"

# get all altuserhosts
if test -n "$userhosts"
then
    test -n "$ALTUSERHOSTS" &&
        userhosts="$userhosts `$STRIPCOMMENTS $ALTUSERHOSTS 2> /dev/null `"
else
    test -z "$ALTUSERHOSTS" && ALTUSERHOSTS="$defaultuserhosts"
    userhosts="`$STRIPCOMMENTS $ALTUSERHOSTS 2> /dev/null`"
fi

test -z "$userhosts" && usage_and_exit 1

for p in "$@"
do
    find_package "$p"

    if test -z "$PARFILE"
    then
        warning "Cannot find package file $p"
        continue
    fi

    LOGDIR="$altlogdir"
    if test -z "$LOGDIR" -o | -d "$LOGDIR" -o | -w "$LOGDIR"
    then
        for LOGDIR in "`dirname $PARFILE`/log/$p" $BUILDHOME/logs/$p \
                        /usr/tmp /var/tmp /tmp
    do
        test -d "$LOGDIR" || mkdir -p "$LOGDIR" 2> /dev/null
        test -d "$LOGDIR" -a -w "$LOGDIR" && break
    done
fi
msg="Check build logs for $p in `hostname`:$LOGDIR"
echo "$msg"

echo "$msg" | $MAIL -s "$msg: $USER 2> /dev/null"

for u in $userhosts
do
    build_one $u
done

test $EXITCODE -gt 125 && EXITCODE=125

exit $EXITCODE 











