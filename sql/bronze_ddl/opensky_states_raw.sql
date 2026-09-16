CREATE TABLE airline_cloud_warehouse.bronze.opensky_states_raw (
  icao24 STRING  COMMENT 'Unique ICAO 24-bit transponder address (hex)',
  callsign STRING  COMMENT 'Callsign, may contain trailing whitespace padding from source',
  origin_country STRING  COMMENT 'Country of aircraft registration',
  time_position BIGINT COMMENT 'Unix timestamp of last position update',
  last_contact BIGINT COMMENT 'Unix timestamp of last contact with the receiver network',
  longitude DOUBLE,
  latitude DOUBLE,
  baro_altitude DOUBLE COMMENT 'Barometric altitude in meters',
  on_ground BOOLEAN,
  velocity DOUBLE COMMENT 'Ground speed in m/s',
  true_track DOUBLE COMMENT 'Heading in degrees, clockwise from north',
  vertical_rate DOUBLE COMMENT 'Rate of climb/descent in m/s',
  sensors STRING ,
  geo_altitude DOUBLE COMMENT 'Geometric altitude in meters',
  squawk STRING  COMMENT 'Transponder squawk code',
  spi BOOLEAN COMMENT 'Special purpose indicator',
  position_source BIGINT COMMENT '0=ADS-B, 1=ASTERIX, 2=MLAT, 3=FLARM',
  snapshot_time BIGINT COMMENT 'Unix timestamp of the API response as a whole',
  _ingested_at TIMESTAMP,
  _source_file STRING ,
  _rescued_data STRING )
USING delta
COMMENT 'Raw aircraft state vectors from OpenSky Network REST API, filtered to a continental US bounding box.'
CLUSTER BY (snapshot_time);