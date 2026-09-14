{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select *
from read_files(
    '{{ var("date_path", "dbfs:/Volumes/data_mart/source/my_volume/date.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)