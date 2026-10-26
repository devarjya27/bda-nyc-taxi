# Two laptop cluster setup

Use this guide when both teammates are on the same Wi-Fi or wired LAN. Laptop A runs the NameNode, ResourceManager, DataNode 1, and NodeManager 1. Laptop B runs DataNode 2 and NodeManager 2. This demonstrates workers on separate physical laptops.

## 1. Prepare both laptops

On **both** laptops, install the required tools:

```bash
sudo apt update
sudo apt install -y podman podman-compose curl git
podman run --rm docker.io/library/alpine:3.20 echo Podman-works
```

Clone or copy the same project folder to both laptops. If the GitHub repository has been pushed, use:

```bash
git clone https://github.com/devarjya27/bda-nyc-taxi.git retail-taxi-hadoop
cd retail-taxi-hadoop
```

Download this file in a browser on **both** laptops and place it in each project root. It is intentionally excluded from Git:

<https://archive.apache.org/dist/spark/spark-3.5.4/spark-3.5.4-bin-hadoop3.tgz>

Build the identical image on **both** laptops:

```bash
cd /path/to/retail-taxi-hadoop
chmod +x scripts/*.sh
podman build -f Containerfile.local -t taxi-hadoop .
```

## 2. Find the LAN addresses

Connect both laptops to the same network. On each laptop, run:

```bash
hostname -I
```

Choose the IPv4 address on the shared LAN. Example:

| Laptop | Example IP | Role |
| --- | --- | --- |
| A | `192.168.1.10` | Master and worker 1 |
| B | `192.168.1.11` | Worker 2 |

From laptop B, confirm laptop A is reachable:

```bash
ping -c 3 192.168.1.10
```

If UFW is enabled, permit traffic from the other laptop on each machine:

```bash
# Run on A, using B's address.
sudo ufw allow from 192.168.1.11

# Run on B, using A's address.
sudo ufw allow from 192.168.1.10
```

## 3. Start laptop A: master and worker 1

On laptop A, create `.env` using its own LAN address in both fields:

```bash
cd /path/to/retail-taxi-hadoop
cp .env.master .env

podman-compose -f compose.master.yml --env-file .env up -d
podman ps
```

Open these pages from laptop A or laptop B:

- NameNode: `http://192.168.1.10:9870`
- YARN: `http://192.168.1.10:8088`
- Spark History: `http://192.168.1.10:18080`

## 4. Start laptop B: worker 2

On laptop B, set `MASTER_HOST` to laptop A's address and `NODE_HOST` to laptop B's address:

```bash
cd /path/to/retail-taxi-hadoop
cp .env.worker .env

podman-compose -f compose.worker.yml --env-file .env up -d
podman ps
```

## 5. Verify the two physical workers

Run these only on laptop A:

```bash
./scripts/wait-for-cluster.sh
podman exec hadoop-master hdfs dfsadmin -report
podman exec hadoop-master yarn node -list
```

Proceed only when HDFS reports **2 live DataNodes** and YARN reports **2 RUNNING NodeManagers**. In the NameNode UI, the two DataNodes should have different LAN addresses, one for each laptop.

## 6. Load and run from laptop A

Run the project commands only on laptop A, because it owns the master container:

```bash
./scripts/load-dataset.sh
./scripts/run-analysis.sh
```

Use the YARN UI to show the Spark jobs distributed across both NodeManagers:

```bash
podman exec hadoop-master yarn application -list -appStates FINISHED
podman exec hadoop-master hdfs dfs -cat '/project/output/batch/top_pickup_hours/part-*'
podman exec hadoop-master hdfs dfs -cat '/project/output/batch/payment_summary/part-*'
podman exec hadoop-master hdfs dfs -cat '/project/output/batch/distance_fare_summary/part-*'
```

## 7. Stop the cluster

On laptop A:

```bash
podman-compose -f compose.master.yml --env-file .env down
```

On laptop B:

```bash
podman-compose -f compose.worker.yml --env-file .env down
```

Do not add `-v` unless you intend to delete that laptop's HDFS storage.

