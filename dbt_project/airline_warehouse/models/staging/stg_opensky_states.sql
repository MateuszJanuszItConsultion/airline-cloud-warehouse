{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'opensky_states_raw') }}
),

renamed AS (
    SELECT
        icao24,
        trim(callsign) AS callsign,
        origin_country,
        cast(from_unixtime(time_position) AS timestamp) AS position_timestamp,
        cast(from_unixtime(last_contact) AS timestamp) AS last_contact_timestamp,
        cast(from_unixtime(snapshot_time) AS timestamp) AS snapshot_timestamp,
        longitude,
        latitude,
        baro_altitude,
        geo_altitude,
        on_ground,
        velocity,
        true_track,
        vertical_rate,
        squawk,
        spi,
        position_source,
        _ingested_at,
        _source_file
    FROM source
),

deduplicated AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY icao24, snapshot_timestamp
            ORDER BY _ingested_at DESC
        ) AS _row_num
    FROM renamed
)

SELECT
    icao24,
    callsign,
    origin_country,
    position_timestamp,
    last_contact_timestamp,
    snapshot_timestamp,
    longitude,
    latitude,
    baro_altitude,
    geo_altitude,
    on_ground,
    velocity,
    true_track,
    vertical_rate,
    squawk,
    spi,
    position_source,
    _ingested_at,
    _source_file
FROM deduplicated
WHERE _row_num = 1
