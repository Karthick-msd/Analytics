

{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select *
from read_files(
    '{{ var("subscriptions_path", "dbfs:/Volumes/data_mart/source/my_volume/subscriptions.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)