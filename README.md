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

There are 2 methods to provide data to a Federated DB via backup snapshots
1) Build Atlas Datalake Pipelines
2) Restore to a Temporary Cluster
