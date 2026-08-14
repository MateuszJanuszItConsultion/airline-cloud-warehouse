{{ config(materialized='table') }}

with source as (
    select * from {{ ref('aircraft_snapshot') }}
),

backdated as (
    select
        *,
        min(valid_from) over (partition by tail_number) as first_valid_from
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['tail_number', 'valid_from']) }} as aircraft_scd_key,
        tail_number,
        serial_number,
        manufacturer,
        model,
        variant,
        body_type,
        icao_code,
        iata_code,
        manufacture_year,
        delivery_date,
        total_seat_capacity,
        first_class_seats,
        business_class_seats,
        economy_class_seats,
        max_takeoff_weight_kg,
        range_km,
        operator_airline,
        status,
        case
            when valid_from = first_valid_from then cast('2026-01-01' as timestamp)
            else valid_from
        end as valid_from,
        valid_to,
        valid_to is null as is_current
    from backdated
)

select * from final