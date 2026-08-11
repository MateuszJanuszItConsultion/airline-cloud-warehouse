{{ config(materialized='view') }}

with source as (
    select * from {{ source('bronze', 'aircraft_utilization_raw') }}
),

renamed as (
    select
        cast(fl_date as date)                               as flight_date,
        aircraft_key                                        as aircraft_key,
        airport_code                                        as airport_code,
        operational_status                                  as operational_status,
        is_scheduled_day = 1                                as is_scheduled_day,
        scheduled_flight_count                              as scheduled_flight_count,
        completed_flight_count                              as completed_flight_count,
        cancelled_flight_count                              as cancelled_flight_count,
        block_hours                                         as block_hours,
        flight_hours                                        as flight_hours,
        total_distance_km                                   as total_distance_km,
        total_passengers_carried                            as total_passengers_carried,
        available_seat_kilometers                           as available_seat_kilometers,
        revenue_passenger_kilometers                        as revenue_passenger_kilometers,
        _ingested_at,
        _source_file
    from source
)
select * from renamed