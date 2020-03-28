#!/bin/bash
MYIP=`hostname -I`
# trip trailing spaces
MYIP="$(echo -e "${MYIP}" | sed -e 's/[[:space:]]*$//')"
# replace seeds setting
sed -i.bak "s/listen_address: localhost/listen_address: $MYIP/" /etc/cassandra/cassandra.yaml
