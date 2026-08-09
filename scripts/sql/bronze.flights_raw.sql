DROP TABLE IF EXISTS airline_cloud_warehouse.bronze.flights_raw;

CREATE TABLE airline_cloud_warehouse.bronze.flights_raw (
  fl_date STRING,
  op_carrier STRING,
  op_carrier_fl_num STRING,
  origin STRING,
  dest STRING,
  dep_delay STRING,
  arr_delay STRING,
  cancelled STRING,
  _ingested_at TIMESTAMP,
  _source_file STRING
) USING DELTA;

COPY INTO airline_cloud_warehouse.bronze.flights_raw
FROM (
  SELECT
    FL_DATE            AS fl_date,
    OP_CARRIER         AS op_carrier,
    OP_FL_NUM          AS op_carrier_fl_num,
    ORIGIN             AS origin,
    DEST               AS dest,
    DEP_DELAY          AS dep_delay,
    ARR_DELAY          AS arr_delay,
    CANCELLED          AS cancelled,
    current_timestamp() AS _ingested_at,
    _metadata.file_path AS _source_file
  FROM '/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/sample_flights.csv'
)
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'false');