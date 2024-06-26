#!/bin/bash 

dbName="${1}"
source init.conf
script="script$$.txt"
pipeLine="pipeline$$.json"

# get a list of the collections for the DB
commands="var list = db.getSiblingDB(\"${dbName}\").getCollectionNames(); console.log(list);"
printf "%s" "${commands}" > ${script}
eval SOURCE_CONNECTION_STRING=$(atlas --profile ${profile} cluster describe ${sourceCluster} -o json | jq .connectionStrings.standardSrv )
SOURCE_CONNECTION_STRING="mongodb+srv://${userName}:${passWord}@${SOURCE_CONNECTION_STRING##*//}/${dbName}?tls=true&authSource=admin"
collections=$( mongosh --quiet ${SOURCE_CONNECTION_STRING} ${script} )
eval collections=( $( printf "${collections}" | sed -e's/\[//g' -e's/\]//g' -e's/,//g' | grep -v enxcol ) )

if [[ ${#collections[@]} < 1 ]]
then
  printf "* * * - No collections found for ${dbName}\n"
  exit 1
fi

# make a datalake pipeline for each collection
for col in ${collections[*]}
do
name=${dbName}.${col}

cat <<EOF > "${pipeLine}" 
{
  "groupId": "${groupId}",
  "name": "${name}",
  "sink": {
    "type": "DLS",
    "metadataProvider": "AWS",
    "metadataRegion": "US_WEST_2",
    "partitionFields": [
      {
        "fieldName": "_id"
      }
    ]
  },
  "source": {
    "type": "ON_DEMAND_CPS",
    "clusterName": "${sourceCluster}",
    "databaseName": "${dbName}",
    "collectionName": "${col}",
    "groupId": "${groupId}"
  }
}
EOF

atlas --profile ${profile} dataLakePipelines describe "${name}" > /dev/null 2>&1 && atlas --profile ${profile} dataLakePipelines delete --force "${name}"
atlas --profile ${profile} dataLakePipelines create dummy -f "${pipeLine}"
printf "\n" 

done
printf "\n" 
atlas --profile shared-demo dataLakePipelines list | grep ${dbName}

rm "${script}" "${pipeLine}"
exit 0
