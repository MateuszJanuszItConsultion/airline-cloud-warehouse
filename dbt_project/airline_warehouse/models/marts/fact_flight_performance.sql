{{ config(
    materialized='incremental',
    unique_key=['flight_date', 'carrier_code', 'flight_number', 'origin_airport', 'dest_airport'],
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

SELECT
    cast(date_format(flight_date, 'yyyyMMdd') AS int) AS date_key,
    flight_date,
    carrier_code,
    flight_number,
    origin_airport,
    dest_airport,
    dep_delay_minutes,
    arr_delay_minutes,
    is_cancelled,
    delay_category,
    _ingested_at
FROM {{ ref('stg_flights') }}

{% if is_incremental() %}
    WHERE _ingested_at  > (SELECT max(_ingested_at ) FROM {{ this }})
{% endif %}
