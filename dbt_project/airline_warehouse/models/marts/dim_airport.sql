{{ config(materialized='table') }}

SELECT
    airport_code,
    airport_name,
    city,
    state,
    country,
    timezone
FROM {{ ref('airports') }}
