WITH bronze AS (
    SELECT count(DISTINCT topic, partition, offset) AS messages
    FROM {{ source('bronze', 'aircraft_telemetry_raw') }}
),

silver AS (
    SELECT count(*) AS messages FROM {{ ref('stg_aircraft_telemetry') }}
),

quarantine AS (
    SELECT count(*) AS messages FROM {{ ref('stg_aircraft_telemetry_quarantine') }}
)

SELECT
    bronze.messages AS bronze_messages,
    silver.messages + quarantine.messages AS accounted_messages
FROM bronze
CROSS JOIN silver
CROSS JOIN quarantine
WHERE bronze.messages != silver.messages + quarantine.messages