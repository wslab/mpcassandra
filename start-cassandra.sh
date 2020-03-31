#!/bin/bash

# instance DC
INSTANCE_DC=DC1

# instance cluster name, default "INSTANCE_DC Cluster"
CLUSER_NAME="${INSTANCE_DC} Cluster"

# instance CPU count
INSTANCE_CPU_COUNT=2

# instance RAM size
INSTANCE_RAM=4G

# instance disk size
INSTANCE_DISK_SIZE=20G

# instance count
INSTANCE_COUNT=3

# keyspaces to create, separated by spacd
KEYSPACES_TO_CREATE="sample1 sample2 sample3"

# --- internal config
MULTIPASS_COMMAND=multipass

# --- variables
CURRENT_INSTANCE=""

function echoerr {
    echo "$@" 1>&2
}

function start_instance {
    local instance_name=$1
    local cloud_init_file=$2
    if [ -z "$cloud_init_file" ]
    then
        echo "cloud init file name not provided!"
        return
    fi
    if [ ! -e "$cloud_init_file" ]
    then
        echo "cloud init file $cloud_init_file not found!"
        return
    fi

    echo "starting instance $instance_name, ${INSTANCE_RAM} RAM, ${INSTANCE_CPU_COUNT} CPUS, ${INSTANCE_DISK_SIZE} disk"
    ${MULTIPASS_COMMAND} launch \
    --name $instance_name \
    --cpus $INSTANCE_CPU_COUNT \
    --mem ${INSTANCE_RAM} \
    --disk ${INSTANCE_DISK_SIZE} \
    --cloud-init=${cloud_init_file}
}

function instance_name_for_count {
    local count=$1
    echo "dc1vm${count}"
}

function ip_for_instance {
    local instance_name=$1
    if [ -z "$instance_name" ]
    then
        echoerr "instance name not provided!"
        echo ""
        return
    fi
    local result=`${MULTIPASS_COMMAND} ls|grep ${instance_name}|awk '{print $3}'`
    echoerr found ip for $instance_name: $result
    echo $result
}
# ---

start_instance myinstance /tmp/notexist

for instance_number in $(seq 1 ${INSTANCE_COUNT}) ; do
    instance_name=$(instance_name_for_count $instance_number)
    echo starting Multipass instance $instance_number: $instance_name
    start_instance $instance_name ./cassandra-node.yaml
done

echo waiting 10 seconds for intances to settle
sleep 10

seed_instance_name=$(instance_name_for_count 1)
echo seed_instance_name: $seed_instance_name
seed_instance_ip=$(ip_for_instance $seed_instance_name)
echo seed_instance_ip: $seed_instance_ip

# update seeds
for instance_number in $(seq 1 ${INSTANCE_COUNT}) ; do
    instance_name=$(instance_name_for_count $instance_number)
    echo setting seed for instance $instance_number: $instance_name to $seed_instance_ip
    ${MULTIPASS_COMMAND} exec $instance_name -- sudo /root/import-seeds.sh $seed_instance_ip
done

# start cassandra
for instance_number in $(seq 1 ${INSTANCE_COUNT}) ; do
    instance_name=$(instance_name_for_count $instance_number)
    echo starting cassandra on $instance_number: $instance_name 
    ${MULTIPASS_COMMAND} exec $instance_name -- sudo systemctl start cassandra
done

echo waiting 60 seconds for cassandra to start up
sleep 60

for keyspace in $KEYSPACES_TO_CREATE ; do
    echo Creating keyspace $keyspace
    multipass exec $seed_instance_name -- cqlsh -e "create keyspace $keyspace with replication={'replication_factor': 3, 'class': 'SimpleStrategy'};"
done

echo Startup complete. 
echo You can connect to cassandra by running
echo ${MULTIPASS_COMMAND} exec $seed_instance_name -- cqlsh
