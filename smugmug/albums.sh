#!/bin/bash
# Inspired by http://braindump.dk/tech/2007/10/03/smugmug-uploader/
# Created by Jesse DeFer http://www.dotd.com/smugget/
# creates a mapping of AlbumID to Category/SubCat/Album Name from your gallery
# used with albumsymlinks.sh to create human readable directory tree

which curl >  /dev/null
test $? -gt 0 && echo "Curl is not on the path" && exit 1

test -f ~/.smugup && source ~/.smugup

UA="smugget/1.0 (smugmug@dotd.com)"
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
	    echo "Usage: $0 [-u email] [-p password]"
	    exit 1
    esac
done

test -z "$EMAIL" && echo "Username missing" && exit 1
test -z "$PASSWORD" && echo "Password missing" && exit 1

SID=`curl -k -A "$UA" -s "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.login.withPassword&EmailAddress=$EMAIL&Password=$PASSWORD&APIKey=$APIKEY" | grep SessionID`
SID=${SID/*<SessionID>/}
SID=${SID/<\/SessionID>*/}

test -z $SID && echo "Unable to login" && exit 1

curl -k -A "$UA" -s "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.albums.get&SessionID=$SID&APIKey=$APIKEY"| sed -n '
s/.*<Album id="\(.*\)">/\1/p
' > $0.$$.tmp

rm -f albums.list

cat $0.$$.tmp | while read ALBUM
do
    curl -k -s -A "$UA" "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.albums.getInfo&AlbumID=$ALBUM&SessionID=$SID"| sed -n '
s/.*<Category id="\(.*\)" \/>/\1/p
s/.*<SubCategory id="\(.*\)" \/>/\1/p
s/.*<Title>\(.*\)<\/Title>/\1/p
' | sed -n 'N
N
s/\// /g
s/\n/\//g
s/^/'"$ALBUM"'\//
p' >> albums.list.tmp

done

rm $0.$$.tmp
rm -f albums.list

IFS='/'
cat albums.list.tmp | while read ALBUMID cat subcat line
do

CATNAME=`curl -k -s -A "$UA" "https://api.smugmug.com/hack/rest/1.2.0/?method=smugmug.categories.get&SessionID=$SID" | sed -n '
s/.*<Category id="'"$cat"'" Title="\(.*\)"\/>/\1/p
'`

SUBCATNAME=`curl -k -s -A "$UA" "https://api.smugmug.com/hack/rest/1.2.0/?method=smugmug.subcategories.get&CategoryID=$cat&SessionID=$SID" | sed -n '
s/.*<SubCategory id="'"$subcat"'" Title="\(.*\)"\/>/\1/p
'`

echo $ALBUMID $CATNAME/$SUBCATNAME/$line | sed -e 's/\/\//\//g' >> albums.list

done

rm albums.list.tmp

curl -k -s -o /dev/null -A "$UA" "https://api.smugmug.com/hack/rest/1.1.1/?method=smugmug.logout&SessionID=$SID&APIKey=$APIKEY"
