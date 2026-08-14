{{ config(materialized='table') }}

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2026-01-01' as date)",
        end_date="cast('2031-01-01' as date)"
    ) }}
),

renamed AS (
    SELECT
        cast(date_day AS date)                          AS date_day,
        cast(date_format(date_day, 'yyyyMMdd') AS int)  AS date_key,
        year(date_day)                                  AS year,
        quarter(date_day)                               AS quarter,
        month(date_day)                                 AS month,
        date_format(date_day, 'MMMM')                   AS month_name,
        day(date_day)                                   AS day_of_month,
        dayofweek(date_day)                             AS day_of_week,
        date_format(date_day, 'EEEE')                   AS day_name,
        dayofweek(date_day) IN (1, 7)                   AS is_weekend
    FROM date_spine
)

SELECT * FROM renamed
