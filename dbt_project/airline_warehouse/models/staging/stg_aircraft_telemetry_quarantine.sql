{{ config(materialized='table') }}

SELECT
    key,
    value,
    quarantine_reason,
    kafka_partition,
    kafka_offset,
    kafka_timestamp,
    _ingested_at
FROM {{ ref('stg_aircraft_telemetry_parsed') }}
WHERE quarantine_reason IS NOT NULL
