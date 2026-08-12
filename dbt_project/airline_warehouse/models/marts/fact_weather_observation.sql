{{ config(
    materialized='incremental',
    unique_key=['date_key', 'airport_code'],
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

select
    cast(date_format(observation_date, 'yyyyMMdd') as int) as date_key,
    observation_date,
    airport_code,
    avg_temp_c,
    precipitation_mm,
    avg_wind_speed_kmh,
    visibility_km,
    has_severe_weather,
    season
from {{ ref('stg_weather') }}

{% if is_incremental() %}
where observation_date > (select max(observation_date) from {{ this }})
{% endif %}