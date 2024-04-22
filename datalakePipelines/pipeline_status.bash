#!/bin/bash

# monitor the progress of the pipeline updates (coping)
dbName="${1}"
source init.conf

list=( $( atlas --profile ${profile} dataLakePipelines list | grep ${dbName} ) )

len=${#list[@]}
if [[ $len < 1 ]]
then
    printf "* * * error: No pipelines match $dbName\n"
    exit 1
fi

complete=1
while [ $complete -eq 1 ]
do
n=1
alldone=0
date
while [ $n -lt $len ]
do
    name=${list[$n]}
    eval state=($( atlas --profile ${profile} dataLakePipelines runs list --pipeline $name -o json | jq ".results[].phase,.results[].state"))

    [[ ${state[1]} != "DONE" ]] && alldone=1

    printf "pipeline %s status: %s\n" "${name}" "${state[*]}"
    #atlas --profile ${profile} dataLakePipelines runs list --pipeline $name -o json|jq ".results[].state,.results[].stats"
    n=$((n+3))
done
if [[ $alldone == 0 ]] 
then
    complete=0
else
    sleep 60
    printf "Sleeping for 60 seconds\n\n"
fi

done
exit 0
