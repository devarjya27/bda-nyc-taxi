#!/usr/bin/env bash
set -e
sed -i "s|MASTER_HOST|${MASTER_HOST:?Set MASTER_HOST to this laptop's LAN IP}|g" /opt/hadoop/etc/hadoop/*.xml
sed -i "s|NODE_HOST|${NODE_HOST:?Set NODE_HOST to this laptop's LAN IP}|g" /opt/hadoop/etc/hadoop/*.xml
if [ ! -f /data/name/current/VERSION ]; then
  hdfs namenode -format -nonInteractive
fi
hdfs --daemon start namenode
yarn --daemon start resourcemanager
for attempt in $(seq 1 15); do
  hdfs dfs -mkdir -p /spark-history && break
  sleep 1
done
# Laptop A is also worker 1.
if [ "${MASTER_RUNS_WORKER:-true}" = "true" ]; then
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi
/opt/spark/sbin/start-history-server.sh
exec tail -f /dev/null

