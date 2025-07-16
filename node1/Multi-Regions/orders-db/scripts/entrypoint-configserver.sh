#!/bin/bash

# Exit the script if there is any error exit status
set -e

# Get the MongoDB PID
MONGO_PID=$!

# Start MongoDB in the background
mongod --configsvr --replSet rs-config-server --port 27017 --bind_ip_all &

# Give some time for the MongoDB to start
sleep 5

# Instance counter
counter=0
config_servers=("orders-db-configsvr01" "orders-db-configsvr02" "orders-db-configsvr03")
num_servers=${#config_servers[@]}
echo $num_servers

# Check MongoDB instance readiness
check_mongo_ready() {
    host=$1
    mongosh --host $host --eval "db.adminCommand('ping')" --quiet
    return $?
}

# Check the readiness of all config-server instances
for host in "${config_servers[@]}"; do
    attempt=0
    max_attempts=30
    until check_mongo_ready $host || [ $attempt -ge $max_attempts ]; do
        echo "Waiting for $host to be ready... (attempt $attempt/$max_attempts)"
        attempt=$((attempt + 1))
        sleep 2
    done
    if [ $attempt -ge $max_attempts ]; then
        echo "Timed out waiting for $host!"
        exit 1
    else
        counter=$((counter + 1))
        echo "$host is ready!"
    fi
done

if [ $counter -lt $num_servers ]; then
    echo "Failed to initialize config servers!"
    exit 1
fi

# Initialize replica set
echo "Initializing config server replica set..."

mongosh eval --eval "
    rs.initiate({
      _id: \"rs-config-server\", 
      configsvr: true, 
      version: 1, 
      members: [ 
        { _id: 0, host : 'orders-db-configsvr01:27017' }, 
        { _id: 1, host : 'orders-db-configsvr02:27017' }, 
        { _id: 2, host : 'orders-db-configsvr03:27017' } 
      ] 
    })
" || echo "Failed to initialized replica set"

echo "Config server replica set initialization attempted!"

wait $MONGO_PID