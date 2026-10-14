# Two-laptop setup and demo

The cluster runs across both laptops.

| Laptop | Services |
| --- | --- |
| Laptop A | NameNode, ResourceManager, Spark History Server, DataNode 1, NodeManager 1 |
| Laptop B | DataNode 2, NodeManager 2 |

Keep both laptops on the same Wi-Fi or LAN.

## 1. Install on both laptops

Use Linux with 12 GB free disk and 8 GB RAM.

```bash
sudo apt update
sudo apt install -y podman podman-compose curl
podman run --rm docker.io/library/alpine:3.20 echo Podman-works
```

Copy the complete project folder to both laptops.

## 2. Find LAN addresses

Run on each laptop:

```bash
hostname -I
```

Call Laptop A's Wi-Fi/LAN IPv4 address `MASTER_IP` and Laptop B's `WORKER_IP`. Do not use `127.0.0.1`, a Podman address, or an address beginning with `172.`.

From Laptop B:

```bash
ping -c 3 MASTER_IP
```

If a firewall is enabled, allow TCP ports `9000`, `9866`, `9870`, `8030-8033`, `8042`, and `8088` between the two laptops.

## 3. Build on both laptops

On both laptops:

```bash
cd /path/to/retail-taxi-hadoop
chmod +x scripts/*.sh
podman build -t taxi-hadoop .
```

The first build downloads Hadoop and Spark and can take several minutes.

## 4. Start Laptop A

On Laptop A:

```bash
cp .env.example .env
```

Set the following in `.env`:

```text
MASTER_HOST=MASTER_IP
NODE_HOST=MASTER_IP
```

Start the master and worker 1:

```bash
podman-compose -f compose.master.yml up -d
podman ps
```

## 5. Start Laptop B

On Laptop B:

```bash
cp .env.example .env
```

Set the following in `.env`:

```text
MASTER_HOST=MASTER_IP
NODE_HOST=WORKER_IP
```

Start worker 2:

```bash
podman-compose -f compose.worker.yml up -d
podman ps
```

## 6. Verify the distributed cluster

Wait about 20 seconds. Run on Laptop A:

```bash
./scripts/wait-for-cluster.sh
podman exec hadoop-master hdfs dfsadmin -report
podman exec hadoop-master yarn node -list
```

Proceed only when HDFS reports **2 live DataNodes** and YARN reports **2 RUNNING NodeManagers**.

Open these pages from Laptop A:

- HDFS: `http://MASTER_IP:9870`
- YARN: `http://MASTER_IP:8088`
- Spark History Server: `http://MASTER_IP:18080`

## 7. Load data and run jobs

Run only on Laptop A:

```bash
./scripts/load-dataset.sh
./scripts/run-analysis.sh
```

The loader streams all 12 official 2023 NYC TLC Yellow Taxi files into HDFS. The combined HDFS dataset exceeds 500 MB; there is no local dataset file.

## 8. Show outputs

```bash
podman exec hadoop-master hdfs dfs -cat /project/output/batch/top_pickup_hours/part-*
podman exec hadoop-master hdfs dfs -cat /project/output/batch/payment_summary/part-*
podman exec hadoop-master hdfs dfs -cat /project/output/batch/distance_fare_summary/part-*
podman exec hadoop-master hdfs dfs -ls /project/output/streaming
```

## 9. Demo roles

You show Laptop A, HDFS, YARN, and Spark submission. Your teammate shows Laptop B's worker container with `podman ps`, explains the dataset and data cleaning, and interprets the output.

## 10. Troubleshooting

On Laptop A:

```bash
podman-compose -f compose.master.yml logs --tail=100
```

On Laptop B:

```bash
podman-compose -f compose.worker.yml logs --tail=100
```

If worker 2 is missing, check the LAN ping, `.env` addresses, and firewall ports. Restart it on Laptop B:

```bash
podman-compose -f compose.worker.yml down
podman-compose -f compose.worker.yml up -d
```

