{{ config(
    materialized='incremental',
    unique_key=['date_key', 'airport_code'],
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

SELECT
    cast(date_format(observation_date, 'yyyyMMdd') AS int) AS date_key,
    observation_date,
    airport_code,
    avg_temp_c,
    precipitation_mm,
    avg_wind_speed_kmh,
    visibility_km,
    has_severe_weather,
    season
FROM {{ ref('stg_weather') }}

{% if is_incremental() %}
    WHERE observation_date > (SELECT max(observation_date) FROM {{ this }})
{% endif %}
