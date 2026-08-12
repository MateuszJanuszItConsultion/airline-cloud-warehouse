{{ config(materialized='table') }}

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
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by observation_date, airport_code
            order by _ingested_at desc
        ) as _row_num
    from renamed
),

enriched as (
    select
        observation_date,
        airport_code,
        avg_temp_c,
        precipitation_mm,
        avg_wind_speed_kmh,
        visibility_km,
        has_severe_weather,
        case
            when month(observation_date) in (12, 1, 2) then 'Winter'
            when month(observation_date) in (3, 4, 5) then 'Spring'
            when month(observation_date) in (6, 7, 8) then 'Summer'
            else 'Fall'
        end as season,
        _ingested_at,
        _source_file
    from deduplicated
    where _row_num = 1
)

select * from enriched