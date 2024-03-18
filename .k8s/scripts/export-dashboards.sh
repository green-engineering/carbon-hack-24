#!/bin/bash
domain=""
instance="$2"
headers="Authorization: Bearer $1"
in_path=dashboards_raw
set -o nounset

if test -z $instance; then
  instance="$domain/grafana"
fi

echo "Exporting Grafana dashboards from $instance"
mkdir -p $in_path
for dash in $(curl -H "$headers" -s "$instance/api/search?query=&" -k | jq -r '.[] | select(.type == "dash-db") | .uid'); do
    curl -H "$headers" -s "$instance/api/search?query=&" -k 1>/dev/null
    dash_path="$in_path/$dash.json"
    curl -H "$headers" -s "$instance/api/dashboards/uid/$dash" -k | jq -r . > $dash_path
    jq -r .dashboard $dash_path > $in_path/dashboard.json
    title=$(jq -r .dashboard.title $dash_path)
    folder="$(jq -r '.meta.folderTitle' $dash_path)"
    mkdir -p "data/${folder}"
    mv -f ${in_path}/dashboard.json "data/${folder}/${title}.json"
    echo "exported $folder/${title}.json"
done
rm -r $in_path
