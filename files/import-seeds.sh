#!/bin/bash
MYIP=$1
if [ "$1" == "" ]; then
   echo usage: import-seeds.sh IP
   exit
fi
# trip trailing spaces
MYIP="$(echo -e "${MYIP}" | sed -e 's/[[:space:]]*$//')"
# replace seeds setting
sed -i.bak "s/127.0.0.1/$MYIP/" /etc/cassandra/cassandra.yaml
