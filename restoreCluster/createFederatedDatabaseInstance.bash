#!/bin/bash

dbName="${1:-test}"
source init.conf
tenantName="federatedDB-${dbName//_/-}"
fileName="fedDBinput$$.json"
# curlData="@"${fileName}

# get a list of the all the dbs and collections in the cluster
genConfiguration.bash "${dbName}" | jq  > "${fileName}"
if [[ $? != 0 ]]
then
    printf "* * * error: no dbs found \n\n"
    exit 1
fi

# delete any old instance of the same name
atlas --profile ${profile} dataFederation delete ${tenantName} --force > /dev/null 2>&1
out=$( atlas --profile ${profile} dataFederation create ${tenantName} -f ${fileName} -o json )

if [[ $? == 0 ]]
then 
    eval hn=$( printf "${out}" | jq .hostnames[0] )
    uri="mongodb://${userName}:${passWord}@${hn}/?tls=true&authSource=admin"
    printf "A Federated Database was created with connection string: \n\t\"${uri}\"\n"
    [[ -e "${fileName}" ]] && rm "${fileName}"
    exit 0
else
    printf "\n\n* * * error: The Federated Database creation failed\n"
    [[ -e "${fileName}" ]] && rm "${fileName}"
    exit 1
fi
