#!/bin/bash

username=$1
password=$2
url=$3
if test -z $username; then
  username="admin"
fi
if test -z $password; then
  password="admin"
fi
if test -z $url; then
  url="http://localhost:4000"
fi

# get a jwt 
jwt=$(curl -X POST -F "username=${username}" -F "password=${password}" "${url}/login" -k | jq -r '.token')

# use jwt to auth further
curl "${url}/api/" -H "Authorization: Bearer ${jwt}" -k
