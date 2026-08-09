{{ config(materialized='view') }}

with source as (
    select * from {{ source('bronze', 'flights_raw') }}
),

renamed as (
    select
        cast(fl_date as date)                               as flight_date,
        op_carrier                                          as carrier_code,
        op_carrier_fl_num                                   as flight_number,
        origin                                              as origin_airport,
        dest                                                as dest_airport,
        cast(round(try_cast(dep_delay as double)) as int)   as dep_delay_minutes,
        cast(round(try_cast(arr_delay as double)) as int)   as arr_delay_minutes,
        cancelled = '1'                     as is_cancelled,
        _ingested_at,
        _source_file
    from source
)

select * from renamed