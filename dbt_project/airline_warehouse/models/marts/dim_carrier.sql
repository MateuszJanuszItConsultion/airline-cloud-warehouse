{{ config(materialized='table') }}

SELECT
    carrier_code,
    carrier_name,
    carrier_type
FROM {{ ref('carriers') }}
