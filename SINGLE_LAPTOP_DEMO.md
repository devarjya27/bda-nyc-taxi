# One laptop demo

Use this guide for the working classroom demo. It creates one NameNode, one ResourceManager, two DataNodes, and two NodeManagers in separate Podman containers.

## Prerequisites

Install Podman, Podman Compose, curl, and a browser:

```bash
sudo apt update
sudo apt install -y podman podman-compose curl
podman run --rm docker.io/library/alpine:3.20 echo Podman-works
```

Download Spark in a browser from the Apache archive and place it in the project root as `spark-3.5.4-bin-hadoop3.tgz`:

<https://archive.apache.org/dist/spark/spark-3.5.4/spark-3.5.4-bin-hadoop3.tgz>

## Start the cluster

```bash
cd /home/indrath/Downloads/retail-taxi-hadoop
chmod +x scripts/*.sh
podman build -f Containerfile.local -t taxi-hadoop .
podman-compose up -d
./scripts/wait-for-cluster.sh
```

The last command must print `Cluster is ready.` Confirm the required nodes:

```bash
podman exec hadoop-master hdfs dfsadmin -report
podman exec hadoop-master yarn node -list
```

HDFS must show **2 live DataNodes** and YARN must show **2 RUNNING NodeManagers**.

## Open the interfaces

- NameNode: <http://localhost:9870>
- YARN: <http://localhost:8088>
- Spark History Server: <http://localhost:18080>

To make HDFS file previews work in the browser, run this once:

```bash
sudo sh -c 'printf "\n127.0.0.1 hadoop-worker-1 hadoop-worker-2\n" >> /etc/hosts'
```

The preview links use Podman's worker names. Both names resolve to the host, and port `9864` serves a replica held by worker 1.

## Load the remote dataset

```bash
./scripts/load-dataset.sh
podman exec hadoop-master hdfs dfs -du -h /project/raw
```

The script streams all twelve 2023 Yellow Taxi Parquet files directly into HDFS. It does not retain a local dataset copy. The 12 files together exceed 500 MB.

## Run and show the analysis

```bash
./scripts/run-analysis.sh
```

In the YARN UI, show the completed batch and streaming applications. In the NameNode UI, browse `Utilities` → `Browse the file system` → `/project/output`.

Show the results in the terminal:

```bash
podman exec hadoop-master hdfs dfs -cat '/project/output/batch/top_pickup_hours/part-*'
podman exec hadoop-master hdfs dfs -cat '/project/output/batch/payment_summary/part-*'
podman exec hadoop-master hdfs dfs -cat '/project/output/batch/distance_fare_summary/part-*'
podman exec hadoop-master hdfs dfs -ls /project/output/streaming
```

## Stop or reset

```bash
# Stop containers; keep HDFS data.
podman-compose down

# Delete all Hadoop data and start from scratch.
podman-compose down -v
```

