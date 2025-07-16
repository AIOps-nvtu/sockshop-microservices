#!/bin/bash

# Exit the script if there is any error exit status
set -e

# Start Redis server in the background
redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes &

# Get the Redis PID
REDIS_PID=$!

# Give some time for the Redis to start
sleep 5

# Instance counter
counter=0
config_servers=("master-node-1" "master-node-2" "session-db" "slave-node-1" "slave-node-2" "slave-node-3")
num_servers=${#config_servers[@]}

# Check Redis instance readiness
check_redis_ready() {
    host=$1
    redis-cli -h $host -c PING --quiet
    return $?
}

# Check the readiness of all server instances
for host in "${config_servers[@]}"; do
    attempt=0
    max_attempts=30
    until check_redis_ready $host || [ $attempt -ge $max_attempts ]; do
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
    echo "Failed to initialize redis servers!"
    exit 1
fi

# Initialize replica set
echo "Initializing Redis server replica set..."

redis-cli --cluster create session-db:6379 master-node-1:6379 master-node-2:6379 --cluster-replicas 0 --cluster-yes &&
    redis-cli --cluster add-node slave-node-1:6379 master-node-1:6379 --cluster-slave &&
    redis-cli --cluster add-node slave-node-2:6379 master-node-2:6379 --cluster-slave &&
    redis-cli --cluster add-node slave-node-3:6379 session-db:6379 --cluster-slave


wait $REDIS_PID