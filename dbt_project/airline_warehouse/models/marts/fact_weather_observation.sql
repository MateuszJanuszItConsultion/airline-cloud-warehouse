{{ config(materialized='table') }}

select
    cast(date_format(observation_date, 'yyyyMMdd') as int) as date_key,
    observation_date,
    airport_code,
    avg_temp_c,
    precipitation_mm,
    avg_wind_speed_kmh,
    visibility_km,
    has_severe_weather
from {{ ref('stg_weather') }}