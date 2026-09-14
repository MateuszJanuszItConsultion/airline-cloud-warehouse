{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'flight_events_raw') }}
),

renamed AS (
    SELECT
        event_id,
        cast(flight_date AS date) AS flight_date,
        carrier_code,
        flight_number,
        origin_airport,
        dest_airport,
        event_type,
        cast(event_timestamp AS timestamp) AS event_timestamp,
        _ingested_at,
        _source_file
    FROM source
),

deduplicated AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY event_id
            ORDER BY _ingested_at DESC
        ) AS _row_num
    FROM renamed
)

SELECT
    event_id,
    flight_date,
    carrier_code,
    flight_number,
    origin_airport,
    dest_airport,
    event_type,
    event_timestamp,
    _ingested_at,
    _source_file
FROM deduplicated
WHERE _row_num = 1
