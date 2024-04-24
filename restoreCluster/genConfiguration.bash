#!/bin/bash

dbName="${1:-test}"
source init.conf

# using a wildcard for the collection names
cat <<EOF1
{
  "name": "${tenantName}",
  "groupId": "${groupId}",
  "storage": {
    "databases": [
EOF1
  printf "\t{\"collections\": [\n"

printf "\t\t{\"name\": \"*\",\n"
printf "\t\t\"dataSources\": [\n"
printf "\t\t\t{\n" 
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
