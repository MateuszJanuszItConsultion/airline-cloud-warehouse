
{{ config(
    materialized='incremental',
    unique_key=['flight_date', 'aircraft_key', 'airport_code'],
    incremental_strategy='merge'
) }}

select
    cast(date_format(flight_date, 'yyyyMMdd') as int) as date_key,
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
    utilization_level
from {{ ref('stg_aircraft_utilization') }}

{% if is_incremental() %}
where flight_date > (select max(flight_date) from {{ this }})
{% endif %}