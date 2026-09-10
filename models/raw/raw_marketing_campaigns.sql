
{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

select *
from read_files(
    '{{ var("marketing_campaigns_path", "dbfs:/Volumes/data_mart/source/my_volume/marketing_campaigns.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)