#!/bin/bash

dbName="${1:-test}"
source init.conf
tenantName="federatedDB-${dbName//_/-}"

list=( $( getCollections.bash ${dbName} ) )
len=${#list[@]}

if [[ $len < 1 ]]
then
    printf "* * * error: No DB match $dbName\n"
    exit 1
fi

cat <<EOF1
{
  "name": "${tenantName}",
  "groupId": "${groupId}",
  "storage": {
    "databases": [
EOF1
  printf "\t{\"collections\": [\n"

n=0
max=$((len-1))
while [ $n -lt $max ]
do
  name=${list[$n]}
  # db=${name%%.*}
  collection=${name#*.}
  printf "\t\t{\"name\": \"${collection}\",\n"
  printf "\t\t\"dataSources\": [\n"
  printf "\t\t\t{\"collection\": \"${collection}\",\n" 
  printf "\t\t\t\"database\":   \"${dbName}\",\n" 
  printf "\t\t\t\"storeName\":  \"${restoreCluster}\"\n" 
  printf "\t\t\t}]\n" 
  printf "\t\t},\n" 

  n=$((n+1))
done

name=${list[$n]}
# db=${name%%.*}
collection=${name#*.}
printf "\t\t{\"name\": \"${collection}\",\n"
printf "\t\t\"dataSources\": [\n"
printf "\t\t\t{\"collection\": \"${collection}\",\n" 
printf "\t\t\t\"database\":   \"${dbName}\",\n" 
printf "\t\t\t\"storeName\":  \"${restoreCluster}\"\n" 
printf "\t\t\t}]\n" 
printf "\t\t}\n" # no comma on the last one

printf "\t],\n" # end of collections
printf "\t\"name\": \"${dbName}\",\n"
printf "\t\"views\": []\n"
printf "    }],\n" # end of databases
cat <<EOF2
    "stores": [{
        "name": "${restoreCluster}",
        "clusterName": "${restoreCluster}",
        "projectId": "${groupId}",
        "provider": "atlas",
        "readPreference": {
          "mode": "primaryPreferred",
          "tagSets": []
        }
    }]
  }
} 
EOF2
exit 0
