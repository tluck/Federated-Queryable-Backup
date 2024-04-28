#!/bin/bash

snapShotId="${1}"
source init.conf
clusterSpec="clusterSpec$$.json"

out=$( atlas --profile "${profile}" cluster describe "${restoreCluster}" -o json 2>&1 )
if [[ $? != 0 ]]
then
    # build a cluster to match the source cluster
    out=$( atlas --profile ${profile} cluster describe ${sourceCluster} -o json )
    versionReleaseSystem=$( printf "${out}" | jq .versionReleaseSystem | tr -d '"' )
    #printf "$out" | jq "del(.id,.name,.biConnector,.backupEnabled,.connectionStrings)" > ${clusterSpec}
    if [[ ${versionReleaseSystem} == "CONTINUOUS" ]]
    then
        printf "Creating a new cluster: ${restoreCluster} ...\n"
        printf "The source cluster is a CONTINOUS cluster - creating a new cluster with the same version\n"
        printf "${out}" | jq "del(.id,.name,.biConnector,.backupEnabled,.connectionStrings,.replicationSpecs[0].regionConfigs[1],.replicationSpecs[0].regionConfigs[2])"\
                        | sed -e 's/"nodeCount": ./"nodeCount": 3/' > ${clusterSpec}
        atlas --profile ${profile} cluster create ${restoreCluster} -f ${clusterSpec} -w
    else
        printf "The source cluster is a RELEASE cluster - creating a new cluster with the same version\n"
        eval providerName=$(            printf "${out}" | jq .replicationSpecs[0].regionConfigs[0].providerName )
        eval regionName=$(              printf "${out}" | jq .replicationSpecs[0].regionConfigs[0].regionName )
        eval instanceSize=$(            printf "${out}" | jq .replicationSpecs[0].regionConfigs[0].electableSpecs.instanceSize )
        eval mongoDBMajorVersion=$(     printf "${out}" | jq .mongoDBMajorVersion )
        eval diskSizeGB=$(              printf "${out}" | jq .diskSizeGB )
        eval clusterType=$(             printf "${out}" | jq .clusterType )
        eval shards=$(                  printf "${out}" | jq .replicationSpecs[0].numShards )
        if [[ ${clusterType} == "REPLICASET" ]]
        then
            type="--type REPLICASET"
        else
            type="--type SHARDED --shards ${shards}"
        fi
        atlas --profile ${profile} cluster create ${restoreCluster} \
          --provider "${providerName}" \
          --region "${regionName}" \
          --members 3 \
          --tier "${instanceSize}" \
          --mdbVersion "${mongoDBMajorVersion}" \
          --diskSizeGB "${diskSizeGB}" \
          ${type} -w
    fi
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