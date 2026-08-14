{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'aircraft_utilization_raw') }}
),

renamed AS (
    SELECT
        cast(fl_date AS date)                               AS flight_date,
        aircraft_key,
        airport_code,
        operational_status,
        is_scheduled_day = 1                                AS is_scheduled_day,
        scheduled_flight_count,
        completed_flight_count,
        cancelled_flight_count,
        block_hours,
        flight_hours,
        total_distance_km,
        total_passengers_carried,
        available_seat_kilometers,
        revenue_passenger_kilometers,
        _ingested_at,
        _source_file
    FROM source
),

deduplicated AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY flight_date, aircraft_key, airport_code
            ORDER BY _ingested_at DESC
        ) AS _row_num
    FROM renamed
),

enriched AS (
    SELECT
        flight_date,
        aircraft_key,
        airport_code,
        operational_status,
        is_scheduled_day,
        scheduled_flight_count,
        completed_flight_count,
        cancelled_flight_count,
        block_hours,
        flight_hours,
        total_distance_km,
        total_passengers_carried,
        available_seat_kilometers,
        revenue_passenger_kilometers,
        CASE
            WHEN operational_status != 'Active' THEN 'grounded'
            WHEN NOT is_scheduled_day THEN 'idle'
            WHEN completed_flight_count >= 3 THEN 'heavy_use'
            ELSE 'light_use'
        END AS utilization_level,
        _ingested_at,
        _source_file
    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM enriched
