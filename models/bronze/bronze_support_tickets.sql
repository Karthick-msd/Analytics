{{
  config(
    materialized = 'table',
    )
}}
select * from read_files (
    'dbfs:/Volumes/data_mart/source/my_volume/support_tickets.csv',
    format => 'csv',
    inferSchema => true,
    header => true
)