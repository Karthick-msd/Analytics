
{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select *
from read_files(
    '{{ var("returns_path", "dbfs:/Volumes/data_mart/source/my_volume/returns.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)