from pyspark.sql import SparkSession
from pyspark.sql.functions import col

spark = SparkSession.builder.appName("aircraft-telemetry-consumer").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

raw = (
    spark.readStream.format("kafka")
    .option("kafka.bootstrap.servers", "kafka:29092")
    .option("subscribe", "aircraft-telemetry")
    .option("startingOffsets", "earliest")
    .load()
)

messages = raw.select(
    col("key").cast("string").alias("key"),
    col("value").cast("string").alias("value"),
    col("partition"),
    col("offset"),
    col("timestamp").alias("kafka_timestamp"),
)

query = (
    messages.writeStream.format("console")
    .option("truncate", "false")
    .option("numRows", 250)
    .trigger(availableNow=True)
    .start()
)

query.awaitTermination()
total_rows = sum(p["numInputRows"] for p in query.recentProgress)
print(f"TOTAL ROWS READ: {total_rows}")