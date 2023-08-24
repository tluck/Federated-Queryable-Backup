#!/bin/bash

dbName="${1}"
source init.conf
tenantName="federatedDB-${dbName//_/-}"

list=( $( atlas --profile ${profile} dataLakePipelines list | grep ${dbName} ) )
len=${#list[@]}

if [[ $len < 1 ]]
then
    printf "* * * error: No pipelines match $dbName\n"
    exit 1
fi

cat <<EOF1
{
  "dataProcessRegion": {
        "cloudProvider": "AWS",
        "region": "OREGON_USA"
  },
  "name": "${tenantName}",
  "storage": {
    "databases": [
      {
        "collections": [
EOF1

n=1
max=$((len-3))
while [ $n -lt $max ]
do
  name=${list[$n]}
  db=${name%.*}
  collection=${name#*.}
  printf "{ \"name\": \"${collection}\",\n\"dataSources\": ["
  printf "{ \"datasetPrefix\": \"v1\$atlas\$snapshot\$${sourceCluster}\$${db}\$${collection}\",\n" 
  printf "  \"storeName\": \"aws-dls-store-us-west-2\" }]},\n" 

  n=$((n+3))
done

name=${list[$n]}
db=${name%.*}
collection=${name#*.}
printf "{ \"name\": \"${collection}\",\n\"dataSources\": ["
printf "{ \"datasetPrefix\": \"v1\$atlas\$snapshot\$${sourceCluster}\$${db}\$${collection}\",\n" 
printf "  \"storeName\": \"aws-dls-store-us-west-2\" }]}\n" 

cat <<EOF2
        ],
        "name": "${dbName}",
        "views": []
      }
    ],
    "stores": [
      {
        "name": "aws-dls-store-us-west-2",
        "provider": "dls:aws",
        "region": "US_WEST_2"
      }
    ]
  }
} 
EOF2
exit 0
