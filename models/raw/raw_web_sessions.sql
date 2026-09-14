
{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select *
from read_files(
    '{{ var("web_sessions_path", "dbfs:/Volumes/data_mart/source/my_volume/web_sessions.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)