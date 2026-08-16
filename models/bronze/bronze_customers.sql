{{ config(materialized='table') }}

SELECT *
FROM read_files(
   '{{ var("customers_path","dbfs:/Volumes/data_mart/source/my_volume/customers.csv") }}',

    format => 'csv',
    header => true,
    inferSchema => true
) 