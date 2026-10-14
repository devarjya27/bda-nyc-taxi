# NYC Taxi Fare and Demand Analysis on Hadoop

This mini project analyses a public NYC Yellow Taxi dataset. It uses a three-node HDFS/YARN cluster, a dataset larger than 500 MB stored in HDFS, Spark submitted on YARN, and two Spark components:

1. Spark SQL/DataFrames for cleaning and analysis.
2. Spark Structured Streaming for an incoming-trip summary.

It deliberately avoids machine learning.

## Problem statement

NYC taxi operators need evidence about demand by hour, fare by trip distance, and payment behaviour. This project processes public Yellow Taxi trips in HDFS with Spark on YARN, producing simple demand and fare insights plus a short streaming result.

## Dataset

Official NYC TLC Yellow Taxi Trip Records, January--December 2023, Parquet.

This 12-file collection exceeds 500 MB and contains millions of trip records. The loader streams each file directly into HDFS; it never creates a local dataset copy. Documentation and source: <https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>.

## Two-laptop deployment

Laptop A runs the NameNode, ResourceManager, and worker 1. Laptop B runs worker 2. Follow [SETUP_AND_DEMO.md](SETUP_AND_DEMO.md) for the required two-laptop instructions.

## Commands run on Laptop A

```bash
podman build -t taxi-hadoop .
podman-compose -f compose.master.yml up -d
./scripts/wait-for-cluster.sh
./scripts/load-dataset.sh
./scripts/run-analysis.sh
```

Open HDFS at `http://MASTER_IP:9870`, YARN at `http://MASTER_IP:8088`, and Spark History at `http://MASTER_IP:18080`.

Results are in `hdfs:///project/output/batch` and `hdfs:///project/output/streaming`.

## Viva sequence

1. In HDFS UI, show the 12 files under `/project/raw`.
2. In YARN UI, show completed batch and streaming applications.
3. Run `podman exec hadoop-master hdfs dfs -cat /project/output/batch/top_pickup_hours/part-*`.
4. Explain the topology: one NameNode/ResourceManager, two DataNode/NodeManagers.
5. Explain cleaning: missing timestamps, nonpositive fare/distance, and invalid duration are rejected.


