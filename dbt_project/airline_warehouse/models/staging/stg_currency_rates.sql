{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'currency_rates_raw') }}
),

renamed AS (
    SELECT
        currency_code,
        base_currency,
        rate_to_base,
        cast(rate_date AS date) AS rate_date,
        _ingested_at,
        _source_file
    FROM source
),

deduplicated AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY currency_code, rate_date
            ORDER BY _ingested_at DESC
        ) AS _row_num
    FROM renamed
)

SELECT
    currency_code,
    base_currency,
    rate_to_base,
    rate_date,
    _ingested_at,
    _source_file
FROM deduplicated
WHERE _row_num = 1
