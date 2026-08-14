CREATE TABLE IF NOT EXISTS airline_cloud_warehouse.bronze.aircraft_utilization_raw (
  fl_date STRING COMMENT 'Flight operation date (YYYY-MM-DD)',
  aircraft_key STRING 'Aircraft registration/tail number (e.g., SP-LRA)',
  airport_code STRING 'IATA code of the base/starting airport for the day',
  operational_status STRING 'Aircraft operational status (Active, Maintenance, Retired)',
  is_scheduled_day INT COMMENT 'Flag indicating if the aircraft was scheduled (1 = Yes, 0 = No)',
  scheduled_flight_count INT COMMENT 'Total number of scheduled flights for the day',
  completed_flight_count INT COMMENT 'Total number of completed flights for the day',
  cancelled_flight_count INT COMMENT 'Total number of cancelled flights for the day',
  block_hours DOUBLE COMMENT 'Total block time (gate-to-gate) in hours',
  flight_hours DOUBLE COMMENT 'Total airborne time (flight hours) in hours',
  total_distance_km INT COMMENT 'Total flight distance covered in kilometers',
  total_passengers_carried INT COMMENT 'Total number of passengers carried across all flights',
  available_seat_kilometers BIGINT COMMENT 'ASK - Available Seat Kilometers (Total seats x distance)',
  revenue_passenger_kilometers BIGINT COMMENT 'RPK - Revenue Passenger Kilometers (Passengers x distance)',
  _ingested_at TIMESTAMP,
  _source_file STRING)
USING delta
COMMENT 'Fleet utilization fact table (Grain: 1 row per aircraft per day)'
CLUSTER BY (fl_date)
