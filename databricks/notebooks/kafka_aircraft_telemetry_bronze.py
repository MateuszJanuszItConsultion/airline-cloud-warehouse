# Databricks notebook source
from pyspark.sql.functions import col, current_timestamp

bootstrap_servers = dbutils.secrets.get(scope="kafka-aiven", key="bootstrap_servers")
ca_pem = dbutils.secrets.get(scope="kafka-aiven", key="ca_pem")
service_cert = dbutils.secrets.get(scope="kafka-aiven", key="service_cert")
service_key = dbutils.secrets.get(scope="kafka-aiven", key="service_key")

bronze_table = "airline_cloud_warehouse.bronze.aircraft_telemetry_raw"
checkpoint_path = "/Volumes/airline_cloud_warehouse/bronze/streaming_checkpoints/aircraft_telemetry/"

raw = (
    spark.readStream.format("kafka")
    .option("kafka.bootstrap.servers", bootstrap_servers)
    .option("subscribe", "aircraft-telemetry")
    .option("startingOffsets", "earliest")
    .option("kafka.security.protocol", "SSL")
    .option("kafka.ssl.truststore.type", "PEM")
    .option("kafka.ssl.truststore.certificates", ca_pem)
    .option("kafka.ssl.keystore.type", "PEM")
    .option("kafka.ssl.keystore.certificate.chain", service_cert)
    .option("kafka.ssl.keystore.key", service_key)
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
    bronze.writeStream
    .option("checkpointLocation", checkpoint_path)
    .trigger(availableNow=True)
    .toTable(bronze_table)
)

query.processAllAvailable()