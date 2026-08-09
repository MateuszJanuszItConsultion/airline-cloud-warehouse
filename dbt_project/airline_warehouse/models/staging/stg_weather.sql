{{ config(materialized='view') }}

with source as (
    select * from {{ source('bronze', 'weather_raw') }}
),

renamed as (
    select
        cast(obs_date as date)              as observation_date,
        airport_code,
        avg_temp_c,
        precipitation_mm,
        avg_wind_speed_kmh,
        visibility_km,
        has_severe_weather = 1              as has_severe_weather,
        _ingested_at,
        _source_file
    from source
)

select * from renamed