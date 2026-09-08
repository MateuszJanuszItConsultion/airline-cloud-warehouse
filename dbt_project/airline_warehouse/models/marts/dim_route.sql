{{ config(materialized='table') }}

WITH routes AS (
    SELECT DISTINCT
        origin_airport,
        dest_airport
    FROM {{ ref('stg_flights') }}
),

enriched AS (
    SELECT
        r.origin_airport,
        r.dest_airport,
        origin.country AS origin_country,
        dest.country AS dest_country,
        origin.country != dest.country AS is_international
    FROM routes AS r
    LEFT JOIN {{ ref('dim_airport') }} AS origin ON r.origin_airport = origin.airport_code
    LEFT JOIN {{ ref('dim_airport') }} AS dest ON r.dest_airport = dest.airport_code
)

SELECT
    origin_airport,
    dest_airport,
    origin_country,
    dest_country,
    is_international
FROM enriched
