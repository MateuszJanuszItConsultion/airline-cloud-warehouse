CREATE TABLE IF NOT EXISTS airline_cloud_warehouse.bronze.weather_raw (
  obs_date STRING,
  airport_code STRING,
  avg_temp_c DOUBLE,
  precipitation_mm DOUBLE,
  avg_wind_speed_kmh DOUBLE,
  visibility_km DOUBLE,
  has_severe_weather BIGINT,
  _ingested_at TIMESTAMP,
  _source_file STRING)
USING delta