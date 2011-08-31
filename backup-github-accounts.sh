#!/bin/bash

for ACCOUNT in realityforge stocksoftware; do

  export ACCOUNT_LOCATION="$HOME/Backups/github/$ACCOUNT"

  export REPO_LIST=`curl --silent  https://api.github.com/users/$ACCOUNT/repos | grep git_url | tr ',"' ' ' | awk '{print $3}' | xargs echo`

  mkdir -p $ACCOUNT_LOCATION

  for REPO in $REPO_LIST; do
	export BASE_NAME=`basename $REPO .git`
	export LOCATION="$ACCOUNT_LOCATION/$BASE_NAME"
	echo "Backing up $ACCOUNT/$BASE_NAME to $LOCATION"
    rm -rf $LOCATION
    git clone --bare $REPO $LOCATION
    (cd $LOCATION && git remote add --mirror origin $REPO)
  done

done
