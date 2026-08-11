
{{ config(
    materialized='incremental',
    unique_key=['flight_date', 'carrier_code', 'flight_number', 'origin_airport', 'dest_airport'],
    incremental_strategy='merge'
) }}

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

{% if is_incremental() %}
where flight_date > (select max(flight_date) from {{ this }})
{% endif %}