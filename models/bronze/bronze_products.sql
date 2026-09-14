{{
  config(
    materialized='incremental',
    file_format='delta',
    incremental_strategy='append',
  )
}}

-- Products is a slowly changing dimension source (unit_cost/unit_price drift over
-- time), so bronze appends every load as-is. We decide what to DO with history
-- (SCD2 or overwrite) later, in staging/intermediate -- never in bronze.
select
    *,
    current_timestamp()     as _bronze_loaded_at,
    '{{ invocation_id }}'   as _dbt_run_id
from {{ ref('raw_products') }}
