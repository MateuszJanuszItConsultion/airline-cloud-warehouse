{% test no_missing_business_keys(model, compare_model, target_key_columns, source_key_columns) %}

with source_keys as (
    select distinct
        {% for col in source_key_columns %}
        cast({{ col }} as string) as key_{{ loop.index }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from {{ compare_model }}
),

target_keys as (
    select distinct
        {% for col in target_key_columns %}
        cast({{ col }} as string) as key_{{ loop.index }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from {{ model }}
),

missing as (
    select * from source_keys
    except
    select * from target_keys
)

select * from missing

{% endtest %}