#/bin/bash

GIT_TAG=$(git describe --always --tags)
TAG_VERSION=${GIT_TAG}
VERSION_REGEX="^v[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"

if [[ $TAG_VERSION =~ $VERSION_REGEX ]];
then
    echo "${TAG_VERSION}"
else
    echo "dev"
fi

