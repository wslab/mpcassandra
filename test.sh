#!/bin/bash

KEYSPACES_TO_CREATE="sample1 sample2"

for keyspace in $KEYSPACES_TO_CREATE ; do 
 multipass exec dc2vm1 -- cqlsh -e "create keyspace $keyspace with replication={'replication_factor': 3, 'class': 'SimpleStrategy'};"
done
