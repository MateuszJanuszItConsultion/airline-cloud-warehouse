{{ config(materialized='table') }}

SELECT
    tail_number,
    to_timestamp(event_timestamp) AS event_timestamp,
    latitude,
    longitude,
    altitude_m,
    velocity_ms,
    heading_deg,
    tick,
    kafka_partition,
    kafka_offset,
    kafka_timestamp,
    _ingested_at
FROM {{ ref('stg_aircraft_telemetry_parsed') }}
WHERE quarantine_reason IS NULL
