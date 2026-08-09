{{ config(materialized='table') }}

select
    carrier_code,
    carrier_name,
    carrier_type
from {{ ref('carriers') }}