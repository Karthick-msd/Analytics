{{
  config(
    materialized='table',
    file_format='delta'
  )
}}

-- Raw = the literal contents of the CSV, converted from Volume storage into
-- a real Delta table. No renaming, no filtering, no incremental logic here —
-- this model exists solely to give every downstream layer real Delta file
-- statistics to work with, instead of re-scanning a CSV every run.
select *
from read_files(
    '{{ var("inventory_path", "dbfs:/Volumes/data_mart/source/my_volume/inventory.csv") }}',
    format => 'csv',
    header => true,
    inferSchema => true
)