#!/usr/bin/env bash
set -e
sed -i "s|MASTER_HOST|${MASTER_HOST:?Set MASTER_HOST to Laptop A's LAN IP}|g" /opt/hadoop/etc/hadoop/*.xml
sed -i "s|NODE_HOST|${NODE_HOST:?Set NODE_HOST to this laptop's LAN IP}|g" /opt/hadoop/etc/hadoop/*.xml
hdfs --daemon start datanode
yarn --daemon start nodemanager
exec tail -f /dev/null

