from pyspark.sql import SparkSession, Window
from pyspark.sql.functions import col, from_json, row_number, to_timestamp, when
from pyspark.sql.types import DoubleType, IntegerType, StringType, StructField, StructType

BASE_PATH = "/opt/spark/work-dir/kafka"
BRONZE_PATH = f"{BASE_PATH}/bronze/aircraft_telemetry"
SILVER_PATH = f"{BASE_PATH}/silver/aircraft_telemetry"
QUARANTINE_PATH = f"{BASE_PATH}/quarantine/aircraft_telemetry"

TELEMETRY_SCHEMA = StructType(
    [
        StructField("tail_number", StringType()),
        StructField("latitude", DoubleType()),
        StructField("longitude", DoubleType()),
        StructField("altitude_m", DoubleType()),
        StructField("velocity_ms", DoubleType()),
        StructField("heading_deg", DoubleType()),
        StructField("tick", IntegerType()),
        StructField("event_timestamp", StringType()),
        StructField("_corrupt_record", StringType()),
    ]
)

spark = SparkSession.builder.appName("aircraft-telemetry-silver").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

bronze = spark.read.parquet(BRONZE_PATH)

dedup_window = Window.partitionBy("partition", "offset").orderBy(col("_ingested_at").desc())
deduplicated = bronze.withColumn("_rn", row_number().over(dedup_window)).where(col("_rn") == 1).drop("_rn")

parsed = deduplicated.withColumn(
    "data",
    from_json(
        col("value"),
        TELEMETRY_SCHEMA,
        {"mode": "PERMISSIVE", "columnNameOfCorruptRecord": "_corrupt_record"},
    ),
)

classified = parsed.withColumn(
    "quarantine_reason",
    when(col("data").isNull() | col("data._corrupt_record").isNotNull(), "malformed_json")
    .when(
        col("data.tail_number").isNull() | col("data.altitude_m").isNull() | col("data.event_timestamp").isNull(),
        "schema_mismatch",
    )
    .when(col("data.tail_number") != col("key"), "key_mismatch"),
).cache()

silver = classified.where(col("quarantine_reason").isNull()).select(
    col("data.tail_number").alias("tail_number"),
    to_timestamp(col("data.event_timestamp")).alias("event_timestamp"),
    col("data.latitude").alias("latitude"),
    col("data.longitude").alias("longitude"),
    col("data.altitude_m").alias("altitude_m"),
    col("data.velocity_ms").alias("velocity_ms"),
    col("data.heading_deg").alias("heading_deg"),
    col("data.tick").alias("tick"),
    col("partition").alias("kafka_partition"),
    col("offset").alias("kafka_offset"),
    col("kafka_timestamp"),
    col("_ingested_at"),
)

quarantine = classified.where(col("quarantine_reason").isNotNull()).select(
    "key", "value", "quarantine_reason", "partition", "offset", "kafka_timestamp", "_ingested_at"
)

silver.write.mode("overwrite").parquet(SILVER_PATH)
quarantine.write.mode("overwrite").parquet(QUARANTINE_PATH)

print(f"SILVER ROWS: {spark.read.parquet(SILVER_PATH).count()}")
print(f"QUARANTINE ROWS: {spark.read.parquet(QUARANTINE_PATH).count()}")