#!/bin/bash

export RF_REPOS=`curl --silent  https://api.github.com/users/realityforge/repos | grep git_url | tr ',"' ' ' | awk '{print $3}' | xargs echo`
export SS_REPOS=`curl --silent  https://api.github.com/users/stocksoftware/repos | grep git_url | tr ',"' ' ' | awk '{print $3}' | xargs echo`

export REPO_LIST="$RF_REPOS $SS_REPOS"

for REPO in $REPO_LIST; do
	echo "Backing up $REPO"
    rm -rf `basename $REPO`
    git clone --bare $REPO `basename $REPO`
    (cd `basename $REPO` && git remote add --mirror origin $REPO)
done