#!/bin/sh
# Created by Jesse DeFer http://www.dotd.com/smugget/
# run albums.sh to create albums.list first

if [ ! -f albums.list ]; then
    echo "Required file albums.list does not exist"
    exit
fi

BASEDIR=`pwd`

cat albums.list | while read ALBUM DIRECTORY
do
    DIR="albums/$DIRECTORY"
    [ ! -d "$DIR" ] && mkdir -p "$DIR"

    [ ! -d "$ALBUM" ] && continue

    cd "$DIR"

    ls "$BASEDIR/$ALBUM" | while read line
    do
	[ -e "$line" ] && continue
	ln -s "$BASEDIR/$ALBUM/$line"
    done

    cd $BASEDIR
done
