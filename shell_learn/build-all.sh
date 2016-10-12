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

# add functions
build_one(){
    # Grammar:
    # build_one [user@]host[:build-directory][,envfile]
    arg="`eval echo $i`"

    userhost="`echo $arg | sed -e 's/:.*$//'`"

    user="`echo $userhost | sed -e 's/@.*$//'`"
    test "$user" = "$userhost" && user=$USER
    
    host="`echo $userhost | sed -e s'/^[^@]*@//'`"

    envfile="`echo $arg | sed -e 's/^[^,]*,//'`"
    test "$envfile" = "$arg" && envfile=/dev/null

    builddir="`echo $arg | sed -e 's/^.*://' -e 's/,.*//'`"
    test "$builddir" = "$arg" && builddir=/tmp

    parbase=`basename $PARFILE`

    # NB: if changed, update find_package()
    package="`echo $parbase | \
        sed -e 's/[.]jar$//' \
            -e 's/[.]tar[.]bz2$//' \
            -e 's/[.]tar[.]gz$//' \
            -e 's/[.]tar[.]Z$//' \
            -e 's/[.]tar$//' \
            -e 's/[.]tgz$//' \
            -e 's/[.]zip$//'`"

    # if we cannot see package file, copy
    echo $SSH $SSHFLAGS $userhost "test -f $PARFILE"
    if $SSH $SSHFLAGS $userhost "test -f $PARFILE"
    then
        parbaselocal=$PARFILE 
    else
        parbaselocal=$parbase 
        echo $SCP $PARFILE $userhost:$builddir
        $SCP $PARFILE $userhost:$builddir 
    fi

    # in remote host, tar file, configure
    # check

    sleep 1
    now="`date $DATEFLAGS`"
    logfile="$package.$host.$now.log"
    nice $SSH $SSHFLAGS $userhost "
        echo '===============================================';
        test -f $BUILDBEGIN && . $BUILDBEGIN || \
            test -f $BUILDBEGIN && source %BUILDBEGIN || \
                true ;
        echo 'Package:                  $package';
        echo 'Archive:                  $PARFILE';
        echo 'Date:                     $now';
        echo 'Local user:               $USER';
        echo 'Local host:               `hostname`';
        echo 'Local log directory:      $LOGDIR';
        echo 'Local log file:           $logfile';
        echo 'Remote user:              $user';
        echo 'Remote host:              $host';
        echo 'Remote directory:         $builddir';
        printf 'Remote date: '
        date $DATEFLAGS;
        printf 'Remote uname: ';
        uname -a || true;
        printf 'Remote gcc version: ';
        gcc --version | head -n 1 || echo;
        printf 'Remote g++ version:';
        g++ --version | head -n 1 || echo;
        echo 'Configure environment:    `$STRIPCOMMENTS $envfile | $JOINLINES`';
        echo 'Extra environment:        $EXTRAENVIRONMENT';
        echo 'Configure directory:      $CONFIGUREDIR';
        echo 'Configure flags:          $CONFIGUREFLAGS';
        echo 'Make all targets:         $ALLTARGETS';
        echo 'Make check targetsL       $CHECKTARGETS';
        echo 'Disk free report for      $builddir/$Package:';
        df $builddir | $INDENT;
        echo 'Environment:';
        env | env LC_ALL=C sort | $INDENT'
        echo '==================================================='
        umask $UMASK;
        cd $builddir || exit 1;
        /bin/rm -rf $builddir/$package;
        $PAR $parbaselocal;
        test "$parbase" = "$parbaselocal" && /bin/rm -f $parbase;
        cd $package/$CONFIGUREDIR || exit 1;
        test -f configure && \
            chmod a+x configure && \
            env `$STRIPCOMMENTS $envfile | $JOINLINES` \
            $EXTRAENVIRONMENT \
            nice time ./configure $CONFIGUREFLAGS;
        nice time make $ALLTARGETS && nice time make $CHECKTARGETS;
        echo '===================================================';
        echo 'Dick free report for $builddir/$package:';
        df $builddir | $INDENT;
        printf 'Remote date:        ';
        date $DATEFLAGS;
        cd ;
        test -f $BUILDEND && . $BUILDEND || \
            test -f $BUILDEND && source $BUILDEND || \
            true;
        echo '===================================================';

    " < /dev/null > "$LOGDIR/$logfile" 2>$1 &
}


error(){
    echo "$@" 1>&2
    usage_and_exit 1
}

find_file(){
    # Grammar:
    #   find_file file program-and-args
    # if find, return 0
    # else return !0
    if test -r "$1"
    then 
        PAR="$2"
        PARFILE="$1"
        return 0;
    else
        return 1

    fi
}

find_package(){
    # Grammar:
    # find_package package-x.y.z
    base=`echo "$1" | sed -e 's/[-_][.]*[0-9].*$//'`

    PAR=
    PARFILE=
    for srcdir in $SRCDIRS 
    do
        test "$srcdir" = "." && srcdir="`pwd`"

        for subdir in "$base" ""
        do
            # NB: if this list changed, update build_one()
            find_file $srcdir/$subdir/$1.tar.gz "tar xfz" && return
            find_file $srcdir/$subdir/$1.tar.Z "tar xfz" && return 
            find_file $srcdir/$subdir/$1.tar "tar xf" && return 
            find_file $srcdir/$subdir/$1.tar.bz2 "tar xfj" return 
            find_file $srcdir/$subdir/$1.taz "tar xfz" && return 
            find_file $srcdir/$subdir/$1.zip "unzip -q" && return 
            find_file $srcdir/$subdir/$1.jar "jar xf" && return 
        done
    done
}


set_userhosts(){
    # Grammar:
    # set_userhosts file(s)
    for u in "$@"
    do 
        if test -r "$u"
        then 
            ALTUSERHOSTS="$ALTUSERHOSTS $u"
        elif test -r "$BUILDHOME/$u"
        then 
            ALTUSERHOSTS="$ALTUSERHOSTS $BUILDHOME/$u"
        else
            error "File not found: $u"
        fi
    done
}

usage(){
    cat <<EOF
Usage:
    $PROGRAM [ --? ]
            [ --all "..." ]
            [ --check "..." ]
            [ --configure "..." ]
            [ --environment "..." ]
            [ --help ]
            [ --logdirectory dir ]
            [ --on "[user@]host[:dir][,envfile] ..." ]
            [ --source "dir ..." ]
            [ --userhosts "file(s)" ]
            [ --version ]
            package(s)
EOF
}

usage_and_exit(){
    usage 
    exit $1
}

version(){
    echo "$PROGRAM version $VERSION"
}

warning(){
    echo "$@" 1>&2
    EXITCODE=`expr $EXITCODE + 1`
}




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






        
        
        
        while test $# -gt 0
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
            shift
            altsrcdirs="$altsrcdirs $1"
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











