CREATE TABLE IF NOT EXISTS airline_cloud_warehouse.bronze.flights_raw (
  fl_date STRING ,
  op_carrier STRING,
  op_carrier_fl_num BIGINT,
  origin STRING,
  dest STRING,
  dep_delay DOUBLE,
  arr_delay DOUBLE,
  cancelled BIGINT,
  _ingested_at TIMESTAMP,
  _source_file STRING)
USING delta
