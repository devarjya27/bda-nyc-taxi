#!/usr/bin/env bash
set -euo pipefail
echo 'Waiting for two DataNodes and two NodeManagers...'
for attempt in $(seq 1 30); do
  dn=$(podman exec hadoop-master hdfs dfsadmin -report 2>/dev/null | sed -n 's/.*Live datanodes ([[:space:]]*\([0-9]*\)).*/\1/p' | head -n1)
  nm=$(podman exec hadoop-master yarn node -list 2>/dev/null | awk '/RUNNING/ {count++} END {print count+0}')
  if [ "${dn:-0}" -ge 2 ] && [ "$nm" -ge 2 ]; then
    podman exec hadoop-master hdfs dfs -mkdir -p /project/raw /project/stream-in /project/output /spark-history
    echo 'Cluster is ready.'
    exit 0
  fi
  sleep 4
done
echo 'Cluster did not become ready. Run: podman-compose logs' >&2
exit 1

