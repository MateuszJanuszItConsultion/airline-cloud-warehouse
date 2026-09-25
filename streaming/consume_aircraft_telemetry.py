from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp

# Must point to storage shared by the driver and all executors (see mounts check)
BASE_PATH = "/opt/spark/work-dir/kafka"
BRONZE_PATH = f"{BASE_PATH}/bronze/aircraft_telemetry"
CHECKPOINT_PATH = f"{BASE_PATH}/checkpoints/aircraft_telemetry_bronze"

spark = SparkSession.builder.appName("aircraft-telemetry-bronze").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

raw = (
    spark.readStream.format("kafka")
    .option("kafka.bootstrap.servers", "kafka:29092")
    .option("subscribe", "aircraft-telemetry")
    .option("startingOffsets", "earliest")
    .load()
)

bronze = raw.select(
    col("key").cast("string").alias("key"),
    col("value").cast("string").alias("value"),
    col("topic"),
    col("partition"),
    col("offset"),
    col("timestamp").alias("kafka_timestamp"),
    current_timestamp().alias("_ingested_at"),
)

query = (
    bronze.writeStream.format("parquet")
    .option("path", BRONZE_PATH)
    .option("checkpointLocation", CHECKPOINT_PATH)
    .trigger(availableNow=True)
    .start()
)

query.awaitTermination()

total_rows = sum(p["numInputRows"] for p in query.recentProgress)
print(f"TOTAL ROWS READ: {total_rows}")