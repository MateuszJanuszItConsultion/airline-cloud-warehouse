{{ config(materialized='table') }}

select
    airport_code,
    airport_name,
    city,
    state,
    country,
    timezone
from {{ ref('airports') }}