#!/usr/bin/env python3
"""Render the three batch-analysis HDFS outputs as one side-by-side PNG."""

import csv
import io
import subprocess
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "analysis-output-plots.png"


def hdfs_csv(path: str) -> list[dict[str, str]]:
    text = subprocess.check_output(
        ["podman", "exec", "hadoop-master", "hdfs", "dfs", "-cat", path],
        text=True,
    )
    return list(csv.DictReader(io.StringIO(text)))


def millions(value: float, _position: int) -> str:
    return f"{value / 1_000_000:.1f}M"


pickup = sorted(hdfs_csv("/project/output/batch/top_pickup_hours/part-*"), key=lambda row: int(row["pickup_hour"]))
payments = sorted(hdfs_csv("/project/output/batch/payment_summary/part-*"), key=lambda row: int(row["payment_type"]))
bands = hdfs_csv("/project/output/batch/distance_fare_summary/part-*")
band_order = ["0-2 miles", "2-5 miles", "5-10 miles", "10+ miles"]
bands = sorted(bands, key=lambda row: band_order.index(row["distance_band"]))

plt.style.use("seaborn-v0_8-whitegrid")
fig, axes = plt.subplots(1, 3, figsize=(19, 6.5), constrained_layout=True)
fig.suptitle("Cab Trips Analysis", fontsize=19, fontweight="bold")

# Pickup hours: trips plus the average-fare trend from the same output.
hours = [int(row["pickup_hour"]) for row in pickup]
trips = [int(row["trips"]) for row in pickup]
fares = [float(row["avg_fare"]) for row in pickup]
ax = axes[0]
ax.bar(hours, trips, color="#2A6FBB", width=0.8, label="Trips")
ax.set_title("Trips by Pickup Hour", fontweight="bold")
ax.set_xlabel("Hour of day")
ax.set_ylabel("Trips")
ax.set_xticks(range(24))
ax.yaxis.set_major_formatter(FuncFormatter(millions))
fare_axis = ax.twinx()
fare_axis.plot(hours, fares, color="#F28E2B", marker="o", markersize=3.5, linewidth=2, label="Average fare")
fare_axis.set_ylabel("Average fare ($)", color="#C66C18")
fare_axis.tick_params(axis="y", labelcolor="#C66C18")
ax.legend(loc="upper left")
fare_axis.legend(loc="upper right")

# Payment types: volume and the average-tip label from the same output.
payment_labels = {
    "0": "Flex fare",
    "1": "Card",
    "2": "Cash",
    "3": "No charge",
    "4": "Dispute",
}
labels = [payment_labels.get(row["payment_type"], f"Type {row['payment_type']}") for row in payments]
payment_trips = [int(row["trips"]) for row in payments]
tips = [float(row["avg_tip"]) for row in payments]
ax = axes[1]
bars = ax.bar(labels, payment_trips, color=["#59A14F", "#4E79A7", "#E15759", "#B07AA1", "#9C755F"])
ax.set_title("Trips by Payment Type", fontweight="bold")
ax.set_ylabel("Trips")
ax.yaxis.set_major_formatter(FuncFormatter(millions))
ax.tick_params(axis="x", rotation=25)
for bar, tip in zip(bars, tips):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), f"Avg tip ${tip:.2f}", ha="center", va="bottom", fontsize=8)

# Distance bands: trip volume plus average-fare labels from the same output.
labels = [row["distance_band"] for row in bands]
distance_trips = [int(row["trips"]) for row in bands]
band_fares = [float(row["avg_fare"]) for row in bands]
ax = axes[2]
bars = ax.bar(labels, distance_trips, color="#76B7B2")
ax.set_title("Trips by Distance Band", fontweight="bold")
ax.set_ylabel("Trips")
ax.yaxis.set_major_formatter(FuncFormatter(millions))
ax.tick_params(axis="x", rotation=20)
for bar, fare in zip(bars, band_fares):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height(), f"Avg fare ${fare:.2f}", ha="center", va="bottom", fontsize=9)

fig.savefig(OUTPUT, dpi=180, bbox_inches="tight")
print(OUTPUT)
