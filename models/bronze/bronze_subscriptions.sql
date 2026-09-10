{{
  config(
    materialized='incremental',
    file_format='delta',
    incremental_strategy='append',
  )
}}

select
    *,
    current_timestamp()     as _bronze_loaded_at,
    '{{ invocation_id }}'   as _dbt_run_id
from {{ ref('raw_subscriptions') }}
