from pyspark.sql.functions import col, current_timestamp

# Databricks notebook source
bronze_table = "airline_cloud_warehouse.bronze.flight_events_raw"
source_path = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/flight_events/"
checkpoint_path = "/Volumes/airline_cloud_warehouse/bronze/streaming_checkpoints/flight_events/"
schema_path = "/Volumes/airline_cloud_warehouse/bronze/streaming_checkpoints/flight_events_schema/"

df = (
    spark.readStream
    .format("cloudFiles")
    .option("cloudFiles.format", "json")
    .option("cloudFiles.schemaLocation", schema_path)
    .option("cloudFiles.inferColumnTypes", "true")
    .load(source_path)
)

# COMMAND ----------



# COMMAND ----------

df_with_metadata = (
    df
    .withColumn("_ingested_at", current_timestamp())
    .withColumn("_source_file", col("_metadata.file_path"))
)

query = (
    df_with_metadata.writeStream
    .format("delta")
    .option("checkpointLocation", checkpoint_path)
    .trigger(availableNow=True)
    .toTable(bronze_table)
)

query.processAllAvailable()