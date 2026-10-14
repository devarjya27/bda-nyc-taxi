#!/usr/bin/env bash
set -e
sed -i "s|MASTER_HOST|${MASTER_HOST:?Set MASTER_HOST to this laptop's LAN IP}|g; s|NODE_HOST|${NODE_HOST:?Set NODE_HOST to this laptop's LAN IP}|g" /opt/hadoop/etc/hadoop/*.xml
if [ ! -f /data/name/current/VERSION ]; then
  hdfs namenode -format -nonInteractive
fi
hdfs --daemon start namenode
yarn --daemon start resourcemanager
# Laptop A is also worker 1.
hdfs --daemon start datanode
yarn --daemon start nodemanager
start-history-server.sh
tail -F /opt/hadoop/logs/* /opt/spark/logs/* 2>/dev/null

