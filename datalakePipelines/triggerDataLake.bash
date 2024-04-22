#!/bin/bash

dbName="${1}"
source init.conf

list=( $( atlas --profile ${profile} dataLakePipelines list | grep ${dbName} ) )
out=$( atlas --profile ${profile} backups snapshots list ${sourceCluster} -o json|jq .results[0].id )
eval latestSnap=$out 
printf "Using snapShotId %s\n" ${latestSnap}

len=${#list[@]}

if [[ $out == "" || $len < 1 ]]
then
    printf "* * * error: Trigger found no pipelines\n"
    exit 1
fi

# for each pipeline, trigger the copy from the latest snap to update the data
n=1
while [ $n -lt $len ]
do
    name=${list[$n]}

    atlas --profile ${profile} dataLakePipelines trigger $name --snapshotId ${latestSnap}
    printf "\n" 

    n=$((n+3))
done
exit 0
