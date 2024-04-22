#!/bin/bash

snapShotId="${1}"
source init.conf
clusterSpec="clusterSpec$$.json"

out=$( atlas --profile "${profile}" cluster describe "${restoreCluster}" -o json 2>&1 )
if [[ $? != 0 ]]
then
    # build a cluster to match the source cluster
    out=$( atlas --profile ${profile} cluster describe ${sourceCluster} -o json )
    printf "$out" | jq "del(.id,.name,.biConnector,.backupEnabled,.connectionStrings)" > ${clusterSpec}
    printf "Creating a new cluster: ${restoreCluster} ...\n"
    atlas --profile ${profile} cluster create ${restoreCluster} -f ${clusterSpec} -w
    # eval instanceSize=$( printf "${out}" | jq .replicationSpecs[0].regionConfigs[0].electableSpecs.instanceSize )
    # eval providerName=$( printf "${out}" | jq .replicationSpecs[0].regionConfigs[0].providerName )
    # eval regionName=$(   printf "${out}" | jq .replicationSpecs[0].regionConfigs[0].regionName )
    # eval diskSizeGB=$(   printf "${out}" | jq .diskSizeGB )
        # --provider "${providerName}" \
        # --region "${regionName}" \
        # --members 3 \
        # --tier "${instanceSize}" \
        # --mdbVersion 7.2 \
        # --diskSizeGB "${diskSizeGB}"
else
    eval paused=$( printf "${out}" | jq .paused )
    if [[ $paused == "true" ]]
    then
        printf "The Cluster is paused - resuming\n"
        atlas --profile ${profile} cluster resume ${restoreCluster} -w
    fi
    printf "Found an existing cluster: ${restoreCluster} \n\n"
fi
if [[ $? != 0 ]]
then
    printf "* * * error: failure to create the restore cluster\n\n"
    exit 1
fi

if [[ $snapShotId == "" ]]
then
    printf "No snapshotId provided - using latest Id\n"
    out=$( atlas --profile ${profile} backups snapshots list ${sourceCluster} -o json|jq .results[0].id )
    eval snapShotId=$out 

    if [[ $out == "" ]]
    then
        printf "* * * error: Did not find any snapshots\n"
        exit 1
    fi
fi
printf "Restoring snapShotId: %s\n" ${snapShotId}

job=$( atlas --profile ${profile} backup restore start automated \
    --clusterName ${sourceCluster} \
    --snapshotId  ${snapShotId} \
    --targetClusterName ${restoreCluster} \
    --targetProjectId ${groupId} \
    -o json | jq .id )
eval job=$job

printf "Watching job: $job\n" 
atlas --profile ${profile} backups restores watch ${job} --clusterName ${sourceCluster}

if [[ $? != 0 ]]
then
    printf "* * * error: failure to restore the cluster\n\n"
    exit 1
fi
printf "The restoreCluster is ready to use\n"
[[ -e "${clusterSpec}" ]] && rm ${clusterSpec}
exit 0