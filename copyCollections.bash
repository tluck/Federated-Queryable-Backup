#!/bin/bash 

# copy the collections from the federated instance back to the target (source)
dbName="${1}"
source init.conf
script="script$$.txt"

tenantName="federatedDB-${dbName//_/-}"

eval federated=( $( atlas --profile ${profile} dataFederation describe ${tenantName} -o json | jq .hostnames |sed -e's/\[//g' -e's/\]//g' -e's/,//g'  ) )
FEDERATION_STRING="mongodb://${userName}:${passWord}@${federated}/?tls=true&authSource=admin"

cat <<EOF > ${script}
db = db.getSiblingDB("${dbName}");
cols = db.getCollectionNames();
cols.forEach(function(col) {
    print(col);
    db[col].aggregate([{'\$out': {
        'atlas': {
        'db': "${dbTarget}", 
        'coll': col, 
        'projectId': "${groupId}", 
        'clusterName': "${sourceCluster}" 
        }
    }}]);
});
EOF

# cat <<EOF > ${script}
# db = db.getSiblingDB("${dbName}");
# cols = db.getCollectionNames();
# cols.forEach(function(col) {
#    print(col);
#    db[col].aggregate([{'\$out': {
#        'db': "${dbTarget}", 
#        'coll': col 
#    }}]);
# });
# EOF

printf "copy collections to ${dbTarget}\n"
mongosh --quiet ${FEDERATION_STRING} ${script} 

rm "${script}"
exit 0
