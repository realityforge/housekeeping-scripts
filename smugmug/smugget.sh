#!/bin/bash
# Original by http://braindump.dk/tech/2007/10/03/smugmug-uploader/
# Modified by Jesse DeFer http://www.dotd.com/smugget/
# Additional modifications by Robert Krawitz
# Downloads SmugMug albums

which curl >  /dev/null
test $? -gt 0 && echo "Curl is not on the path" && exit 1

test -f ~/.smugup && source ~/.smugup

UA="smugget/1.3 (smugmug@dotd.com)"
APIKEY="rjBy6Da5lMEbguUkqwpFEdzmOALQrsIE"
LOG=0
LISTONLY=0
ALBUMSONLY=0

while getopts "a:p:u:lLA" flag; do
    case $flag in
	u)
	    EMAIL=$OPTARG
	    ;;
	p)
	    PASSWORD=$OPTARG
	    ;;
	a)
	    ALBUM=$OPTARG
	    ;;
	l)
	    LOG=1
	    ;;
	L)
	    LISTONLY=1
	    ;;
	A)
	    ALBUMSONLY=1
	    ;;
	*)
	    echo "Usage: $0 [-u email] [-p password] [-a albumId] [-l] [-L] [-A]"
	    exit 1
    esac
done

while [ -z "$EMAIL" ] ; do
    echo -e 'Username: \c'
    read EMAIL
done

while [ -z "$PASSWORD" ] ; do
    oldmodes=`stty -g`
    echo -e 'Password: \c'
    stty -echo
    read PASSWORD
    echo
    stty $oldmodes
done

SID=`curl -k -A "$UA" -s "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.login.withPassword&EmailAddress=$EMAIL&Password=$PASSWORD&APIKey=$APIKEY" | grep SessionID`
SID=${SID/*<SessionID>/}
SID=${SID/<\/SessionID>*/}

test -z $SID && echo "Unable to login" && exit 1

if [ "$ALBUMSONLY" -eq 1 -o -z "$ALBUM" ]; then

curl -k -A "$UA" -s "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.albums.get&SessionID=$SID&APIKey=$APIKEY"|
awk -F'[<\"][^>\"]*[>\"]' \
'BEGIN { ORS="" } /Album / {album = $2; p = 1}; /Title/ {if (p) { print " " $2 ": " album "\n"; p = 0 } }' |
sort -n

if [ "$ALBUMSONLY" -eq 1 ]; then
    exit
fi

echo
echo

read -p "Album ID: " ALBUM

fi

IFS="*"
TMPFILE=$0.$$.tmp

curl -k -s -A "$UA" "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.images.get&SessionID=$SID&AlbumID=$ALBUM&Heavy=1&APIKey=$APIKEY"| sed -n '
/<Info>/,/<\/Info>/ {
    s/.*<Album id="\(.*\)" \/>/\1/p
    s/.*<FileName>\(.*\)<\/FileName>/\1/p
    s/.*<FileName \/>/none/p
    s/.*<Size>\(.*\)<\/Size>/\1/p
    s/.*<OriginalURL>\(.*\)<\/OriginalURL>/\1/p
}' | sed -n 'N
N
N
s/\n/\*/g
s/sm-//g
s/-sm//g
p' | while read albumid filename url size
do
    # If a blank filename is returned it's probably a video
    # or something else I don't know how to handle
    if [ $LISTONLY -eq 1 ]; then
	echo $filename
	continue
    fi
    if [ $filename == "none" ]; then
        echo "Skipping unnamed file in album $albumid"
        continue
    fi
    # Sanity check since sed is a poor XML parser
    if [ $ALBUM -ne $albumid ]; then
        echo "Album IDs don't match, possible XML parsing error"
        break
    fi
    if [ ! -d $albumid ]; then
	mkdir $albumid
    fi
    export FILE_SIZE=`stat -c%s "$albumid/$filename" 2> /dev/null`
    if [ "$FILE_SIZE" != $size ]; then
  		echo "Downloading $albumid/$filename ($size)"
  		if [ $LOG -eq 1 ]; then
    			echo "Downloading $albumid/$filename ($size)" >> smugget.log
  		fi
        curl -s -o "$albumid/$filename" $url
        continue
    fi
    # Size matches, don't download
    if [ $LOG -eq 1 ]; then
        echo "Skipping $albumid/$filename ($size)" >> smugget.log
    fi
done
rm -f $TMPFILE

curl -k -s -o /dev/null -A "$UA" "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.logout&SessionID=$SID&APIKey=$APIKEY"
