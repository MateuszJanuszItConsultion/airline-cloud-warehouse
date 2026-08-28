{{ config(materialized='table') }}

with source as (
    select * from {{ ref('currency_snapshot') }}
),

backdated as (
    select
        *,
        min(valid_from) over (partition by currency_code) as first_valid_from
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['currency_code', 'valid_from']) }} as currency_scd_key,
        currency_code,
        base_currency,
        rate_to_base,
        rate_date,
        case
            when valid_from = first_valid_from then cast('2026-01-01' as timestamp)
            else valid_from
        end as valid_from,
        valid_to,
        valid_to is null as is_current
    from backdated
)

select * from final