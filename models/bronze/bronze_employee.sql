
{{
  config(
    materialized='incremental',
    file_format='delta',
    incremental_strategy='append',
  )
}}

-- Date dimension is a static reference file, not an event stream -> full
-- table refresh every run, not incremental. Never treat a dimension seed
-- like a fact-table event log.
select
    *,
    current_timestamp()   as _bronze_loaded_at,
    '{{ invocation_id }}'          as _dbt_run_id,
    '{{ this.identifier }}'        as _source_table

from {{ ref('raw_employee') }} 
