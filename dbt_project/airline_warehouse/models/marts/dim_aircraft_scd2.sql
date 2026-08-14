{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ ref('aircraft_snapshot') }}
),

backdated AS (
    SELECT
        *,
        min(valid_from) OVER (PARTITION BY tail_number) AS first_valid_from
    FROM source
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['tail_number', 'valid_from']) }} AS aircraft_scd_key,
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
        CASE
            WHEN valid_from = first_valid_from THEN cast('2026-01-01' AS timestamp)
            ELSE valid_from
        END AS valid_from,
        valid_to,
        valid_to IS null AS is_current
    FROM backdated
)

SELECT * FROM final
