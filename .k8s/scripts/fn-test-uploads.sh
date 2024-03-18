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

# test uploads
curl  -i -X POST "${url}/api/dummy/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/dummy.csv" -k
curl  -i -X POST "${url}/api/issues/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/issues.csv" -k
curl  -i -X POST "${url}/api/issue-flows/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/issue-flows.csv" -k
curl  -i -X POST "${url}/api/issue-status-maps/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/issue-status-maps.csv" -k
curl  -i -X POST "${url}/api/changes/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/changes.csv" -k
curl  -i -X POST "${url}/api/code-repos/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/code-repos.csv" -k
curl  -i -X POST "${url}/api/elements-of-value-selected/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/elements-of-value-selected.csv" -k
curl  -i -X POST "${url}/api/elements-of-value/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/elements-of-value.csv" -k
curl  -i -X POST "${url}/api/pipeline-run-jobs/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/pipeline-run-jobs.csv" -k
curl  -i -X POST "${url}/api/pipeline-runs/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/pipeline-runs.csv" -k
curl  -i -X POST "${url}/api/pipelines/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/pipelines.csv" -k
curl  -i -X POST "${url}/api/quality-metrics/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/quality-metrics.csv" -k
curl  -i -X POST "${url}/api/regions/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/regions.csv" -k
curl  -i -X POST "${url}/api/self-service-request/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/self-service-request.csv" -k
curl  -i -X POST "${url}/api/squads/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/squads.csv" -k
curl  -i -X POST "${url}/api/tool-projects/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/tool-projects.csv" -k
curl  -i -X POST "${url}/api/vendor-billing-scopes/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/vendor-billing-scopes.csv" -k
curl  -i -X POST "${url}/api/vendor-logical-groups/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/vendor-logical-groups.csv" -k
curl  -i -X POST "${url}/api/vendor-reported-emissions/upload" -H "Authorization: Bearer ${jwt}" -F document=@"./tests/vendor-reported-emissions.csv" -k

