#!/bin/bash 

dbName="${1}"
source init.conf
tenantName="federatedDB-${dbName//_/-}"

for p in $( atlas --profile ${profile} dataLakePipelines list | grep ${dbName} | awk '{print $2}' )
do 
atlas --profile ${profile} dataLakePipelines delete --force ${p}  
done

atlas --profile ${profile} dataFederation delete ${tenantName} --force 

exit 0
