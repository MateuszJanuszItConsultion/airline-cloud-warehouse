{{ config(materialized='ephemeral') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'aircraft_telemetry_raw') }}
),

deduplicated AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY topic, partition, offset
            ORDER BY _ingested_at DESC
        ) AS _row_num
    FROM source
),

parsed AS (
    SELECT
        key,
        value,
        topic,
        partition AS kafka_partition,
        offset AS kafka_offset,
        kafka_timestamp,
        _ingested_at,
        from_json(
            value,
            'tail_number STRING, latitude DOUBLE, longitude DOUBLE, altitude_m DOUBLE, velocity_ms DOUBLE, '
            || 'heading_deg DOUBLE, tick INT, event_timestamp STRING, _corrupt_record STRING',
            map('mode', 'PERMISSIVE', 'columnNameOfCorruptRecord', '_corrupt_record')
        ) AS data
    FROM deduplicated
    WHERE _row_num = 1
),

-- The linter cannot distinguish struct field access (data.tail_number) from a
-- table-qualified column, so RF01/RF03/AL09 report false positives in this block only.
-- noqa: disable=RF01,RF03,AL09
flattened AS (
    SELECT
        key,
        value,
        topic,
        kafka_partition,
        kafka_offset,
        kafka_timestamp,
        _ingested_at,
        data IS NULL AS _payload_is_null,
        data._corrupt_record AS _corrupt_record,
        data.tail_number AS tail_number,
        data.latitude AS latitude,
        data.longitude AS longitude,
        data.altitude_m AS altitude_m,
        data.velocity_ms AS velocity_ms,
        data.heading_deg AS heading_deg,
        data.tick AS tick,
        data.event_timestamp AS event_timestamp
    FROM parsed
)
-- noqa: enable=RF01,RF03,AL09

SELECT
    *,
    CASE
        WHEN _payload_is_null OR _corrupt_record IS NOT NULL THEN 'malformed_json'
        WHEN tail_number IS NULL OR altitude_m IS NULL OR event_timestamp IS NULL THEN 'schema_mismatch'
        WHEN tail_number != key THEN 'key_mismatch'
    END AS quarantine_reason
FROM flattened
