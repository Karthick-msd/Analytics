{{
  config(
    materialized = 'incremental',
    file_format= ' delta',
    incremental_strategy='append',
    )
}}

select *,
current_timestamp() as bronze_loaded_at,
'{{invocation_id}}' as dbt_run_id
from {{ ref('raw_support_tickets')}}

