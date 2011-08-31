#!/bin/bash
# Original by http://braindump.dk/tech/2007/10/03/smugmug-uploader/
# Modified by Jesse DeFer http://www.dotd.com/smugget/
# Downloads all Albums in an account

which curl >  /dev/null
test $? -gt 0 && echo "Curl is not on the path" && exit 1

test -f ~/.smugup && source ~/.smugup

UA="smugget/1.1 (smugmug@dotd.com)"
APIKEY="rjBy6Da5lMEbguUkqwpFEdzmOALQrsIE"

while getopts "a:p:u:" flag; do
    case $flag in
	u)
	    EMAIL=$OPTARG
	    shift;shift;;
	p)
	    PASSWORD=$OPTARG
	    shift;shift;;
	*)
	    echo "Usage: $0 [-u email] [-p password] [-a albumId] files..."
	    exit 1
    esac
done

test -z "$EMAIL" && echo "Username missing" && exit 1
test -z "$PASSWORD" && echo "Password missing" && exit 1

SID=`curl -k -A "$UA" -s "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.login.withPassword&EmailAddress=$EMAIL&Password=$PASSWORD&APIKey=$APIKEY" | grep SessionID`
SID=${SID/*<SessionID>/}
SID=${SID/<\/SessionID>*/}

test -z $SID && echo "Unable to login" && exit 1

curl -k -A "$UA" -s "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.albums.get&SessionID=$SID&APIKey=$APIKEY"|
awk -F'[<\"][^>\"]*[>\"]' \
'BEGIN { ORS="" } /Album / {album = $2; p = 1}; /Title/ {if (p) { print album " " $2 "\n"; p = 0 } }' |
sort -rn > $0.$$.tmp

curl -k -s -o /dev/null -A "$UA" "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.logout&SessionID=$SID&APIKey=$APIKEY"

cat $0.$$.tmp | while read ALBUM line
do
#    ln -s $ALBUM "$line"
    echo "Downloading $line ($ALBUM)"
    ./smugget.sh -l -a $ALBUM
done
