CREATE TABLE airline_cloud_warehouse.bronze.aircraft_telemetry_raw (
  key STRING,
  value STRING,
  topic STRING,
  partition INT,
  offset BIGINT,
  kafka_timestamp TIMESTAMP,
  _ingested_at TIMESTAMP)
USING delta