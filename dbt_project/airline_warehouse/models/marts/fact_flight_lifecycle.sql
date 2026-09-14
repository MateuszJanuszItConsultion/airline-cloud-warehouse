{{ config(
    materialized='incremental',
    unique_key=['flight_date', 'carrier_code', 'flight_number', 'origin_airport', 'dest_airport'],
    incremental_strategy='merge',
    merge_update_columns=['scheduled_at', 'boarding_at', 'departed_at', 'landed_at', 'arrived_at', 'current_stage', '_last_updated_at']
) }}

WITH events AS (
    SELECT * FROM {{ ref('stg_flight_events') }}
    {% if is_incremental() %}
        WHERE _ingested_at > (SELECT coalesce(max(_last_updated_at), '1900-01-01') FROM {{ this }})
    {% endif %}
),

new_pivoted AS (
    SELECT
        flight_date,
        carrier_code,
        flight_number,
        origin_airport,
        dest_airport,
        max(CASE WHEN event_type = 'scheduled' THEN event_timestamp END) AS scheduled_at,
        max(CASE WHEN event_type = 'boarding' THEN event_timestamp END) AS boarding_at,
        max(CASE WHEN event_type = 'departed' THEN event_timestamp END) AS departed_at,
        max(CASE WHEN event_type = 'landed' THEN event_timestamp END) AS landed_at,
        max(CASE WHEN event_type = 'arrived' THEN event_timestamp END) AS arrived_at,
        max(_ingested_at) AS _last_updated_at
    FROM events
    GROUP BY flight_date, carrier_code, flight_number, origin_airport, dest_airport
),

{% if is_incremental() %}

    existing AS (
        SELECT * FROM {{ this }}
    ),

    merged AS (
        SELECT
            n.flight_date,
            n.carrier_code,
            n.flight_number,
            n.origin_airport,
            n.dest_airport,
            coalesce(n.scheduled_at, e.scheduled_at) AS scheduled_at,
            coalesce(n.boarding_at, e.boarding_at) AS boarding_at,
            coalesce(n.departed_at, e.departed_at) AS departed_at,
            coalesce(n.landed_at, e.landed_at) AS landed_at,
            coalesce(n.arrived_at, e.arrived_at) AS arrived_at,
            n._last_updated_at
        FROM new_pivoted AS n
        LEFT JOIN existing AS e
            ON
                n.flight_date = e.flight_date
                AND n.carrier_code = e.carrier_code
                AND n.flight_number = e.flight_number
                AND n.origin_airport = e.origin_airport
                AND n.dest_airport = e.dest_airport
    )

{% else %}

merged as (
    select * from new_pivoted

)

{% endif %}

SELECT
    flight_date,
    carrier_code,
    flight_number,
    origin_airport,
    dest_airport,
    scheduled_at,
    boarding_at,
    departed_at,
    landed_at,
    arrived_at,
    CASE
        WHEN arrived_at IS NOT null THEN 'arrived'
        WHEN landed_at IS NOT null THEN 'landed'
        WHEN departed_at IS NOT null THEN 'departed'
        WHEN boarding_at IS NOT null THEN 'boarding'
        WHEN scheduled_at IS NOT null THEN 'scheduled'
        ELSE 'unknown'
    END AS current_stage,
    _last_updated_at
FROM merged
