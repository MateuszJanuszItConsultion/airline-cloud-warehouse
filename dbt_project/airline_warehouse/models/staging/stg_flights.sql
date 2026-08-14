{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'flights_raw') }}
),

renamed AS (
    SELECT
        cast(fl_date AS date)              AS flight_date,
        op_carrier                          AS carrier_code,
        op_carrier_fl_num                   AS flight_number,
        origin                               AS origin_airport,
        dest                                 AS dest_airport,
        try_cast(dep_delay AS double)       AS dep_delay_minutes,
        try_cast(arr_delay AS double)       AS arr_delay_minutes,
        cancelled = '1'                     AS is_cancelled,
        _ingested_at,
        _source_file
    FROM source
),

deduplicated AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY flight_date, carrier_code, flight_number, origin_airport, dest_airport
            ORDER BY _ingested_at DESC
        ) AS _row_num
    FROM renamed
),

enriched AS (
    SELECT
        flight_date,
        carrier_code,
        flight_number,
        origin_airport,
        dest_airport,
        dep_delay_minutes,
        arr_delay_minutes,
        is_cancelled,
        CASE
            WHEN is_cancelled THEN 'cancelled'
            WHEN dep_delay_minutes IS null THEN 'unknown'
            WHEN dep_delay_minutes <= 15 THEN 'on_time'
            WHEN dep_delay_minutes <= 60 THEN 'minor_delay'
            ELSE 'major_delay'
        END AS delay_category,
        _ingested_at,
        _source_file
    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM enriched
