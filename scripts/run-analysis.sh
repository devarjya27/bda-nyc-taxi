#!/usr/bin/env bash
set -euo pipefail
podman cp spark/taxi_analysis.scala hadoop-master:/tmp/taxi_analysis.scala
podman cp spark/taxi_stream.scala hadoop-master:/tmp/taxi_stream.scala
podman exec hadoop-master hdfs dfs -rm -r -f /project/output/batch /project/output/streaming /project/stream-in/trips.parquet /project/checkpoints 2>/dev/null || true
podman exec hadoop-master /opt/spark/bin/spark-shell --master yarn --deploy-mode client \
  --conf spark.executor.instances=2 --conf spark.executor.cores=1 --conf spark.executor.memory=1g \
  -i /tmp/taxi_analysis.scala
# Send the preserved local demo file into the watched folder for a brief streaming demo.
podman exec hadoop-master hdfs dfs -cp /project/stream-in/demo_batch/trips.parquet /project/stream-in/trips.parquet
podman exec hadoop-master /opt/spark/bin/spark-shell --master yarn --deploy-mode client \
  --conf spark.executor.instances=2 --conf spark.executor.cores=1 --conf spark.executor.memory=1g \
  -i /tmp/taxi_stream.scala

