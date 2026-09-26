# Databricks notebook source
import json
from datetime import datetime

import requests
from pyspark.sql.functions import col, current_timestamp

TOKEN_URL = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token"
STATES_URL = "https://opensky-network.org/api/states/all"
BBOX = {"lamin": 24.5, "lamax": 49.5, "lomin": -125.0, "lomax": -66.5}

client_id = dbutils.secrets.get(scope="opensky", key="client_id")
client_secret = dbutils.secrets.get(scope="opensky", key="client_secret")

token_response = requests.post(
    TOKEN_URL,
    data={
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
    },
    timeout=10,
)
token_response.raise_for_status()
access_token = token_response.json()["access_token"]

states_response = requests.get(
    STATES_URL,
    headers={"Authorization": f"Bearer {access_token}"},
    params=BBOX,
    timeout=15,
)
states_response.raise_for_status()
data = states_response.json()

STATE_VECTOR_COLUMNS = [
    "icao24", "callsign", "origin_country", "time_position", "last_contact",
    "longitude", "latitude", "baro_altitude", "on_ground", "velocity",
    "true_track", "vertical_rate", "sensors", "geo_altitude", "squawk",
    "spi", "position_source",
]

rows = [dict(zip(STATE_VECTOR_COLUMNS, state)) for state in (data.get("states") or [])]
for row in rows:
    row["snapshot_time"] = data["time"]

output_dir = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/opensky"
output_path = f"{output_dir}/opensky_states_{datetime.now():%Y%m%d_%H%M%S}.json"

with open(output_path, "w") as f:
    for row in rows:
        f.write(json.dumps(row) + "\n")

print(f"Fetched {len(rows)} aircraft states -> {output_path}")

# COMMAND ----------

bronze_table = "airline_cloud_warehouse.bronze.opensky_states_raw"
source_path = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/opensky/"
checkpoint_path = "/Volumes/airline_cloud_warehouse/bronze/streaming_checkpoints/opensky/"
schema_path = "/Volumes/airline_cloud_warehouse/bronze/streaming_checkpoints/opensky_schema/"

df = (
    spark.readStream
    .format("cloudFiles")
    .option("cloudFiles.format", "json")
    .option("cloudFiles.schemaLocation", schema_path)
    .option("cloudFiles.inferColumnTypes", "true")
    .load(source_path)
)

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
