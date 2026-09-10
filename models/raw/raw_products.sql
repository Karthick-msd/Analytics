
{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select *
from read_files(
    '{{ var("products_path", "dbfs:/Volumes/data_mart/source/my_volume/products.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)