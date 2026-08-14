{{ config(materialized='table') }}

WITH flights_agg AS (
    SELECT
        date_key,
        origin_airport AS airport_code,
        count(*)                                                  AS total_flights,
        sum(CASE WHEN is_cancelled THEN 1 ELSE 0 END)             AS cancelled_flights,
        round(avg(dep_delay_minutes), 1)                          AS avg_dep_delay_minutes,
        round(avg(arr_delay_minutes), 1)                          AS avg_arr_delay_minutes,
        sum(CASE WHEN delay_category = 'major_delay' THEN 1 ELSE 0 END) AS major_delay_flights,
        round(
            sum(CASE WHEN delay_category IN ('minor_delay', 'major_delay') THEN 1 ELSE 0 END)
            / cast(count(*) AS double) * 100,
            1
        )                                                         AS pct_flights_delayed
    FROM {{ ref('fact_flight_performance') }}
    GROUP BY date_key, origin_airport
),

weather AS (
    SELECT
        date_key,
        airport_code,
        avg_temp_c,
        precipitation_mm,
        avg_wind_speed_kmh,
        visibility_km,
        has_severe_weather,
        season
    FROM {{ ref('fact_weather_observation') }}
),

utilization_agg AS (
    SELECT
        date_key,
        airport_code,
        count(*)                                                        AS aircraft_present_count,
        sum(completed_flight_count)                                     AS total_completed_flights,
        sum(CASE WHEN utilization_level = 'heavy_use' THEN 1 ELSE 0 END) AS heavy_use_aircraft_count,
        round(avg(block_hours), 1)                                       AS avg_block_hours
    FROM {{ ref('fact_aircraft_utilization') }}
    GROUP BY date_key, airport_code
),

joined AS (
    SELECT
        coalesce(f.date_key, w.date_key, u.date_key)          AS date_key,
        coalesce(f.airport_code, w.airport_code, u.airport_code) AS airport_code,

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

    FROM flights_agg AS f
    FULL OUTER JOIN weather AS w
        ON f.date_key = w.date_key AND f.airport_code = w.airport_code
    FULL OUTER JOIN utilization_agg AS u
        ON
            coalesce(f.date_key, w.date_key) = u.date_key
            AND coalesce(f.airport_code, w.airport_code) = u.airport_code
)

SELECT * FROM joined
