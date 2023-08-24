#!/bin/bash

dbName="${1}"
source init.conf
tenantName="federatedDB-${dbName//_/-}"
fileName="fedDBinput$$.json"
curlData="@"${fileName}

# get a list of the all the pipelines to include in the federated instance
list_pipelines.bash "${dbName}" | jq  > "${fileName}"
if [[ $? != 0 ]]
then
    printf "* * * error: no piplelines found for createDataLakePiplelines\n\n"
    exit 1
fi

# delete any old instance of the same name
atlas --profile ${profile} dataFederation delete ${tenantName} --force > /dev/null 2>&1
# broken
# atlas --profile ${profile} dataFederation create ${name} -f ${fileName} -o json
# atlas --profile ${profile} dataFederation update ${name} -f ${fileName} -o json

# make a federated DB using the json created above
# curl --user "${MONGODB_ATLAS_PUBLIC_KEY}:${MONGODB_ATLAS_PRIVATE_KEY}" --digest \
curl --user "${publicKey}:${privateKey}" --digest \
--header "Accept: application/vnd.atlas.2023-02-01+json" --header "Content-Type: application/json" \
--include \
--request POST "https://cloud.mongodb.com/api/atlas/v2/groups/${groupId}/dataFederation/?pretty=true" \
--data "$curlData"

if [[ $? == 0 ]]
then 
    printf "\n\nFederated Database created\n"
    atlas --profile ${profile} dataFederation describe ${tenantName} -o json | jq .hostnames
else
    printf "\n\n* * * error: Federated Database creation failed\n"
    exit 1
fi

rm "${fileName}"

##--request PATCH "https://cloud.mongodb.com/api/atlas/v2/groups/${groupId}/dataFederation/${tenantName}?pretty=true" \
exit 0
