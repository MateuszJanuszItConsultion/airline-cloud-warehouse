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

select
    currency_code,
    base_currency,
    rate_to_base,
    rate_date
from {{ ref('stg_currency_rates') }}

{% endsnapshot %}