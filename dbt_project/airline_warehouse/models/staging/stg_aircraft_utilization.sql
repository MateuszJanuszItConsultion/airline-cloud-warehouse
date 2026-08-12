{{ config(materialized='table') }}

with source as (
    select * from {{ source('bronze', 'aircraft_utilization_raw') }}
),

renamed as (
    select
        cast(fl_date as date)                               as flight_date,
        aircraft_key,
        airport_code,
        operational_status,
        is_scheduled_day = 1                                as is_scheduled_day,
        scheduled_flight_count,
        completed_flight_count,
        cancelled_flight_count,
        block_hours,
        flight_hours,
        total_distance_km,
        total_passengers_carried,
        available_seat_kilometers,
        revenue_passenger_kilometers,
        _ingested_at,
        _source_file
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by flight_date, aircraft_key, airport_code
            order by _ingested_at desc
        ) as _row_num
    from renamed
),

enriched as (
    select
        flight_date,
        aircraft_key,
        airport_code,
        operational_status,
        is_scheduled_day,
        scheduled_flight_count,
        completed_flight_count,
        cancelled_flight_count,
        block_hours,
        flight_hours,
        total_distance_km,
        total_passengers_carried,
        available_seat_kilometers,
        revenue_passenger_kilometers,
        case
            when operational_status != 'Active' then 'grounded'
            when not is_scheduled_day then 'idle'
            when completed_flight_count >= 3 then 'heavy_use'
            else 'light_use'
        end as utilization_level,
        _ingested_at,
        _source_file
    from deduplicated
    where _row_num = 1
)

select * from enriched