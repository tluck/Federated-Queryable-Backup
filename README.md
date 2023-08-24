# Federated-Queryable-Backup
Example of using MongoDB FederatedDatabase for a DB Restore

##Preparation:
Update init.conf with your values

##Prerequisites: 

*     mongosh
*     atlas cli
*     jq
*     curl

Note: brew install mongosh mongodb-atlas-cli jq

##To run:
Execute _qb.bash in a terminal shell

This script then runs 5 scripts:

1. Step 1: Generating the Pipelines for the selected DB 
1. Step 2: Triggering the Pipeline copy to populate the pipelines
1. Step 3: Creating a federatedDatabase using these pipelines
1. Step 4: Monitoring the progress on updating the pipelines
1. Step 5: Connect to the Federated DB and copy the data to the source - replace the current collections.
