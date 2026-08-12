{{ config(materialized='table') }}

with flights_agg as (
    select
        date_key,
        origin_airport as airport_code,
        count(*)                                                  as total_flights,
        sum(case when is_cancelled then 1 else 0 end)             as cancelled_flights,
        round(avg(dep_delay_minutes), 1)                          as avg_dep_delay_minutes,
        round(avg(arr_delay_minutes), 1)                          as avg_arr_delay_minutes,
        sum(case when delay_category = 'major_delay' then 1 else 0 end) as major_delay_flights,
        round(
            sum(case when delay_category in ('minor_delay', 'major_delay') then 1 else 0 end)
            / cast(count(*) as double) * 100,
        1)                                                         as pct_flights_delayed
    from {{ ref('fact_flight_performance') }}
    group by date_key, origin_airport
),

weather as (
    select
        date_key,
        airport_code,
        avg_temp_c,
        precipitation_mm,
        avg_wind_speed_kmh,
        visibility_km,
        has_severe_weather,
        season
    from {{ ref('fact_weather_observation') }}
),

utilization_agg as (
    select
        date_key,
        airport_code,
        count(*)                                                        as aircraft_present_count,
        sum(completed_flight_count)                                     as total_completed_flights,
        sum(case when utilization_level = 'heavy_use' then 1 else 0 end) as heavy_use_aircraft_count,
        round(avg(block_hours), 1)                                       as avg_block_hours
    from {{ ref('fact_aircraft_utilization') }}
    group by date_key, airport_code
),

joined as (
    select
        coalesce(f.date_key, w.date_key, u.date_key)          as date_key,
        coalesce(f.airport_code, w.airport_code, u.airport_code) as airport_code,

        f.total_flights,
        f.cancelled_flights,
        f.avg_dep_delay_minutes,
        f.avg_arr_delay_minutes,
        f.major_delay_flights,
        f.pct_flights_delayed,

        w.avg_temp_c,
        w.precipitation_mm,
        w.avg_wind_speed_kmh,
        w.visibility_km,
        w.has_severe_weather,
        w.season,

        u.aircraft_present_count,
        u.total_completed_flights,
        u.heavy_use_aircraft_count,
        u.avg_block_hours

    from flights_agg f
    full outer join weather w
        on f.date_key = w.date_key and f.airport_code = w.airport_code
    full outer join utilization_agg u
        on coalesce(f.date_key, w.date_key) = u.date_key
        and coalesce(f.airport_code, w.airport_code) = u.airport_code
)

select * from joined