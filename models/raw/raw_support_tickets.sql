{{
  config(
    materialized = 'table',
    file_format='delta'
    )
}}
select * from read_files (
    '{{ var("support_tickets_path","dbfs:/Volumes/data_mart/source/my_volume/support_tickets.csv") }}',
    format => 'csv',
    inferSchema => true,
    header => true
)
