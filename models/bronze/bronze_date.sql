{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

-- Date dimension is a static reference file, not an event stream -> full
-- table refresh every run, not incremental. Never treat a dimension seed
-- like a fact-table event log.
select
    *,
    current_timestamp()   as _bronze_loaded_at
from {{ ref('raw_date') }} 