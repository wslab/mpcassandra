# MPCassandra

Start a Cassandra cluster on your dev machine in 5 minutes or less.

## Platforms supported:

- Linux (Ubuntu)
- MacOS
- Windows

## Prerequisites:

- Multipass installed 

## Steps

1. Look inside `start-cassandra.sh` and set `INSTANCE_CPU_COUNT`, `INSTANCE_RAM`, `INSTANCE_DISK_SIZE` and `INSTANCE_COUNT`
to desired values (or use defaults).
2. Run `bash start-cassandra.sh` and wait for it to finish.
3. The script will start cassandra cluster with names `dc1vmN` and create new keyspaces called `sample1`, `sample2` and `sample3`.
4. Run `multipass dc1vm1 exec -- cqlsh`
