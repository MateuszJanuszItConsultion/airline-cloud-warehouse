{{ config(materialized='table') }}

select
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
    status
from {{ ref('aircraft') }}