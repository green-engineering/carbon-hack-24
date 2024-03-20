#!/bin/sh
set -e

if test -e "local.env"; then
  set -a # automatically export all variables
  source local.env
  set +a
fi

NAME=$1
# set the NAME if not set
if test -z $NAME; then
  NAME=ch24/prom-exporter-server
fi
VERSION_TAG=$2
# set the VERSION_TAG if not set
if test -z $VERSION_TAG; then
  # VERSION_TAG=`date +%y`.`date +%m`.`date +%d`.$1
  VERSION_TAG=latest
fi

root=$(pwd)

cd ${root}/server
npm i

cd ${root}
echo Docker Build
docker build -t $NAME:$VERSION_TAG --progress=plain .
