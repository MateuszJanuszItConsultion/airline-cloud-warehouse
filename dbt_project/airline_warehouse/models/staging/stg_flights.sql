{{ config(materialized='table') }}

with source as (
    select * from {{ source('bronze', 'flights_raw') }}
),

renamed as (
    select
        cast(fl_date as date)              as flight_date,
        op_carrier                          as carrier_code,
        op_carrier_fl_num                   as flight_number,
        origin                               as origin_airport,
        dest                                 as dest_airport,
        try_cast(dep_delay as double)       as dep_delay_minutes,
        try_cast(arr_delay as double)       as arr_delay_minutes,
        cancelled = '1'                     as is_cancelled,
        _ingested_at,
        _source_file
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by flight_date, carrier_code, flight_number, origin_airport, dest_airport
            order by _ingested_at desc
        ) as _row_num
    from renamed
),

enriched as (
    select
        flight_date,
        carrier_code,
        flight_number,
        origin_airport,
        dest_airport,
        dep_delay_minutes,
        arr_delay_minutes,
        is_cancelled,
        case
            when is_cancelled then 'cancelled'
            when dep_delay_minutes is null then 'unknown'
            when dep_delay_minutes <= 15 then 'on_time'
            when dep_delay_minutes <= 60 then 'minor_delay'
            else 'major_delay'
        end as delay_category,
        _ingested_at,
        _source_file
    from deduplicated
    where _row_num = 1
)

select * from enriched