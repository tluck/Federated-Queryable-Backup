#!/bin/bash 

dbName="${1:-test}"
source init.conf
script="script$$.txt"

eval RESTORE_CONNECTION_STRING=$(atlas --profile ${profile} cluster describe ${restoreCluster} -o json | jq .connectionStrings.standardSrv )
RESTORE_CONNECTION_STRING="mongodb+srv://${userName}:${passWord}@${RESTORE_CONNECTION_STRING##*//}/${dbName}?tls=true&authSource=admin"

# get a list of the collections for the DB
commands="var list = db.getSiblingDB(\"${dbName}\").getCollectionNames(); console.log(list);"
printf "%s" "${commands}" > ${script}
collections=$( mongosh --quiet $RESTORE_CONNECTION_STRING ${script} )
eval collections=( $( printf "${collections}" | sed -e's/\[//g' -e's/\]//g' -e's/,//g' | grep -v enxcol ) )

if [[ ${#collections[@]} < 1 ]]
then
  printf "* * * error: No collections found for ${dbName}\n"
  [[ -e "${script}" ]] && rm "${script}"
  exit 1
fi

# list out the names in format: db.collection
for col in ${collections[*]}
do
  printf "${dbName}.${col}\n"
done
[[ -e "${script}" ]] && rm "${script}"
exit 0