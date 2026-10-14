import org.apache.spark.sql.functions._

val schema = spark.read.parquet("hdfs:///project/raw/*.parquet").schema
val incoming = spark.readStream.schema(schema).parquet("hdfs:///project/stream-in")
val summary = incoming.filter(col("fare_amount") > 0).select(hour(col("tpep_pickup_datetime")).alias("pickup_hour"), col("PULocationID"), col("fare_amount"))
val query = summary.writeStream.format("csv").option("path", "hdfs:///project/output/streaming")
  .option("checkpointLocation", "hdfs:///project/checkpoints/taxi_stream").option("header", "true")
  .outputMode("append").trigger(org.apache.spark.sql.streaming.Trigger.AvailableNow()).start()
query.awaitTermination()
System.exit(0)
