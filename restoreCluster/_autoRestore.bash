#!/bin/bash

dbName="${1:-test}"
source init.conf

time1=$(date +%s)
date 
printf "\nStep 1: Listing the snapshots for the source cluster\n\n"
atlas --profile ${profile} backup snapshots list ${sourceCluster} 
printf "\n"
read -p "Enter the snapshotId: " snapShotId
printf "\n"

date 
printf "\nStep 2: Creating a temporary cluster to restore the data\n\n"
restoreCluster.bash ${snapShotId}
if [[ $? != 0 ]]
then
    printf "* * * error: failure to restore the cluster\n\n"
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
printf "\nStep 4: Connect to the Federated DB and copy the data\n\n"
# tenantName="federatedDB-${dbName//_/-}"
# atlas --profile ${profile} dataFederation describe ${tenantName} -o json | jq .storage.databases[].collections[].name
copyCollections.bash ${dbName}

date
time2=$(date +%s)
secs=$((time2-time1))
mins=$( echo "scale=1; ${secs}/60"|bc )
printf "%s seconds = %s minutes\n" "${secs}" "${mins}"
