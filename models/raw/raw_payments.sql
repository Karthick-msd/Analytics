
{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select *
from read_files(
    '{{ var("payments_path", "dbfs:/Volumes/data_mart/source/my_volume/payments.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)