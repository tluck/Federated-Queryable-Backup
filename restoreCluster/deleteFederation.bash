#!/bin/bash 

dbName="${1:-test}"
source init.conf
tenantName="federatedDB-${dbName//_/-}"

atlas --profile ${profile} dataFederation delete ${tenantName} --force 
atlas --profile ${profile} cluster delete ${restoreCluster} --force 

exit 0
