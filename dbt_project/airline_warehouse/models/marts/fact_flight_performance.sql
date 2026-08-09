
{{ config(materialized='table') }}

select
    cast(date_format(flight_date, 'yyyyMMdd') as int) as date_key,
    flight_date,
    carrier_code,
    flight_number,
    origin_airport,
    dest_airport,
    dep_delay_minutes,
    arr_delay_minutes,
    is_cancelled
from {{ ref('stg_flights') }}