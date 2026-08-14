{% snapshot aircraft_snapshot %}

{{
    config(
        target_schema='gold',
        unique_key='tail_number',
        strategy='check',
        check_cols=['status', 'operator_airline', 'total_seat_capacity'],
        snapshot_meta_column_names={
            'dbt_valid_from': 'valid_from',
            'dbt_valid_to': 'valid_to',
            'dbt_scd_id': 'scd_id',
            'dbt_is_deleted': 'is_deleted',
            'dbt_updated_at': 'updated_at',
        }
    )
}}

select * from {{ ref('aircraft') }}

{% endsnapshot %}