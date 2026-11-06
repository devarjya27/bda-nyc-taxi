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

