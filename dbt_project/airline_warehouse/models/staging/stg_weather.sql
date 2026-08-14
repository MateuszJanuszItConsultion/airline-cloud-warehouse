{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'weather_raw') }}
),

renamed AS (
    SELECT
        cast(obs_date AS date)              AS observation_date,
        airport_code,
        avg_temp_c,
        precipitation_mm,
        avg_wind_speed_kmh,
        visibility_km,
        has_severe_weather = 1              AS has_severe_weather,
        _ingested_at,
        _source_file
    FROM source
),

deduplicated AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY observation_date, airport_code
            ORDER BY _ingested_at DESC
        ) AS _row_num
    FROM renamed
),

enriched AS (
    SELECT
        observation_date,
        airport_code,
        avg_temp_c,
        precipitation_mm,
        avg_wind_speed_kmh,
        visibility_km,
        has_severe_weather,
        CASE
            WHEN month(observation_date) IN (12, 1, 2) THEN 'Winter'
            WHEN month(observation_date) IN (3, 4, 5) THEN 'Spring'
            WHEN month(observation_date) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Fall'
        END AS season,
        _ingested_at,
        _source_file
    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM enriched
