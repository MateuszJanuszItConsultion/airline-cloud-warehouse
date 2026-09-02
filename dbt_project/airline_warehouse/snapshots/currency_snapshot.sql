{% snapshot currency_snapshot %}

{{
    config(
        target_schema='gold',
        unique_key='currency_code',
        strategy='check',
        check_cols=['rate_to_base'],
        snapshot_meta_column_names={
            'dbt_valid_from': 'valid_from',
            'dbt_valid_to': 'valid_to',
            'dbt_scd_id': 'scd_id',
            'dbt_is_deleted': 'is_deleted',
            'dbt_updated_at': 'updated_at',
        }
    )
}}

with latest as (
    select
        currency_code,
        base_currency,
        rate_to_base,
        rate_date,
        row_number() over (partition by currency_code order by rate_date desc) as _rn
    from {{ ref('stg_currency_rates') }}
)

select
    currency_code,
    base_currency,
    rate_to_base,
    rate_date
from latest
where _rn = 1

{% endsnapshot %}