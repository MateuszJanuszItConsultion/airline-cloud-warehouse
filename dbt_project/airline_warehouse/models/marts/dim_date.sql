{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2026-01-01' as date)",
        end_date="cast('2031-01-01' as date)"
    ) }}
),

renamed as (
    select
        cast(date_day as date)                          as date_day,
        cast(date_format(date_day, 'yyyyMMdd') as int)  as date_key,
        year(date_day)                                  as year,
        quarter(date_day)                               as quarter,
        month(date_day)                                 as month,
        date_format(date_day, 'MMMM')                   as month_name,
        day(date_day)                                   as day_of_month,
        dayofweek(date_day)                             as day_of_week,
        date_format(date_day, 'EEEE')                   as day_name,
        case when dayofweek(date_day) in (1, 7) then true else false end as is_weekend
    from date_spine
)

select * from renamed