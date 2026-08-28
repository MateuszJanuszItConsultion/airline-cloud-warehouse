{{ config(materialized='table') }}

with source as (
    select * from {{ source('bronze', 'currency_rates_raw') }}
),

renamed as (
    select
        currency_code,
        base_currency,
        rate_to_base,
        cast(rate_date as date) as rate_date,
        _ingested_at,
        _source_file
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by currency_code, rate_date
            order by _ingested_at desc
        ) as _row_num
    from renamed
)

select
    currency_code,
    base_currency,
    rate_to_base,
    rate_date,
    _ingested_at,
    _source_file
from deduplicated
where _row_num = 1
