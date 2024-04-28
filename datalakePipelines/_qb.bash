#!/bin/bash

dbName="${1:-test}"
source init.conf

date 
time1=$(date +%s)

printf "\nStep 1: Generating the Pipelines for DB ${dbName}\n\n"
#deleteDataLakePiplelines.bash ${dbName}
createDataLakePiplelines.bash ${dbName}
if [[ $? != 0 ]]
then
    printf "* * * error: failure to run createDataLakePiplelines\n\n"
    exit 1
fi

date 
printf "\nStep 2: Triggering the Pipelines copy for the pipelines\n\n"
triggerDataLake.bash ${dbName}
if [[ $? != 0 ]]
then
    printf "* * * error: failure to run triggerDataLake\n\n"
    exit 1
fi

date 
printf "\nStep 3: Creating a federatedDatabase for the pipelines\n\n" 
createFederatedDatabaseInstance.bash ${dbName}
if [[ $? != 0 ]]
then
    printf "* * * error: failure to run createFederatedDatabaseInstance\n\n"
    exit 1
fi

date 
printf "\nStep 4: Monitoring the progress on updating the pipelines\n\n"
pipeline_status.bash ${dbName}
if [[ $? != 0 ]]
then
    printf "* * * error: failure to run pipeline_status\n\n"
    exit 1
fi

date 
tenantName="federatedDB-${dbName//_/-}"
printf "\nStep 5: Connect to the Federated DB and copy the data\n\n"
atlas --profile ${profile} dataFederation describe ${tenantName} -o json | jq .storage.databases[].collections[].name

copyCollections.bash ${dbName}

date
time2=$(date +%s)
secs=$((time2-time1))
mins=$( echo "scale=1; ${secs}/60"|bc )
printf "%s seconds = %s minutes\n" "${secs}" "${mins}"
