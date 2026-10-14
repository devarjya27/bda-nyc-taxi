#!/usr/bin/env bash
set -euo pipefail
echo 'Streaming all 12 official NYC TLC Yellow Taxi files for 2023 directly into HDFS...'
for month in {01..12}; do
  dataset_url="https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-${month}.parquet"
  target="/project/raw/yellow_tripdata_2023-${month}.parquet"
  echo "Loading 2023-${month}..."
  curl -fL --progress-bar "$dataset_url" | podman exec -i hadoop-master hdfs dfs -put -f - "$target"
done
podman exec hadoop-master hdfs dfs -du -h /project/raw

