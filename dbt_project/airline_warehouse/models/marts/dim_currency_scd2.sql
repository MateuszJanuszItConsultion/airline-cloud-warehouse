{{ config(materialized='table') }}

WITH source AS (
    SELECT * FROM {{ ref('currency_snapshot') }}
),

backdated AS (
    SELECT
        *,
        min(valid_from) OVER (PARTITION BY currency_code) AS first_valid_from
    FROM source
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['currency_code', 'valid_from']) }} AS currency_scd_key,
        currency_code,
        base_currency,
        rate_to_base,
        rate_date,
        CASE
            WHEN valid_from = first_valid_from THEN cast('2026-01-01' AS timestamp)
            ELSE valid_from
        END AS valid_from,
        valid_to,
        valid_to IS null AS is_current
    FROM backdated
)

SELECT * FROM final
