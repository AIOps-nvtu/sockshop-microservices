#!/bin/bash

# Wait for the config server replica set to elect a primary
echo "Waiting for config server replica set to elect a primary..."
until mongosh --host rs-config-server/carts-db-configsvr01:27017,carts-db-configsvr02:27017,carts-db-configsvr03:27017 --eval 'rs.status().members.some(m => m.stateStr === "PRIMARY")' | grep -q 'true'; do
    sleep 5
done

# Wait for each shard's replica set to elect a primary
for shard in 1 2 3; do
    replica_set="rs-shard-0${shard}"
    host_prefix="carts-db-shard0${shard}"
    echo "Waiting for ${replica_set} to elect a primary..."
    until mongosh --host ${replica_set}/${host_prefix}-a:27017,${host_prefix}-b:27017,${host_prefix}-c:27017 --eval 'rs.status().members.some(m => m.stateStr === "PRIMARY")' | grep -q 'true'; do
        sleep 5
    done
done

# Start mongos in the background
echo "Starting mongos..."
mongos --port 27017 --configdb rs-config-server/carts-db-configsvr01:27017,carts-db-configsvr02:27017,carts-db-configsvr03:27017 --bind_ip_all &

# Wait for mongos to become available
echo "Waiting for mongos to start..."
until mongosh --port 27017 --eval 'db.adminCommand({ping: 1})' &>/dev/null; do
    sleep 5
done

# Add the shards using the provided commands
echo "Adding shards..."
mongosh --port 27017 <<EOF
sh.addShard("rs-shard-01/carts-db-shard01-a:27017")
sh.addShard("rs-shard-01/carts-db-shard01-b:27017")
sh.addShard("rs-shard-01/carts-db-shard01-c:27017")
sh.addShard("rs-shard-02/carts-db-shard02-a:27017")
sh.addShard("rs-shard-02/carts-db-shard02-b:27017")
sh.addShard("rs-shard-02/carts-db-shard02-c:27017")
sh.addShard("rs-shard-03/carts-db-shard03-a:27017")
sh.addShard("rs-shard-03/carts-db-shard03-b:27017")
sh.addShard("rs-shard-03/carts-db-shard03-c:27017")
sh.enableSharding("data")
db.adminCommand( { shardCollection: "data.customerOrder", key: { oemNumber: "hashed", zipCode: 1, supplierId: 1 }, numInitialChunks: 3 } )
EOF

# Keep the mongos process running in the foreground
wait