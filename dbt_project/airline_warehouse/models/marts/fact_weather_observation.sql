{{ config(
    materialized='incremental',
    unique_key=['date_key', 'airport_code'],
    incremental_strategy='merge'
) }}

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

{% if is_incremental() %}
where observation_date > (select max(observation_date) from {{ this }})
{% endif %}