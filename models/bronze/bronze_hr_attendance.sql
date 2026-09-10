
{{
  config(
    materialized='incremental',
    file_format='delta',
    incremental_strategy='append',
  )
}}
 
-- Bronze = the "call recording" of the pipeline. We do NOT clean, cast, or judge
-- the data here. We just prove "this is exactly what the source sent us, and when."
select
    *,
    current_timestamp()            as _bronze_loaded_at,
    '{{ invocation_id }}'          as _dbt_run_id,
    '{{ this.identifier }}'        as _source_table
from {{ ref('raw_hr_attendance') }}
 
